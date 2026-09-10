import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dsh_mobile/layers/auth/data/models/app_user_model.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, AppUser>> login(String email, String password) async {
    try {
      final res = await _dataSource.signIn(email.trim(), password);
      final authUser = res.user;

      if (authUser == null) {
        return const Left(ServerFailure('Sign in failed. Please try again.'));
      }

      return Right(await _resolveUser(authUser, ensureProfile: true));
    } on sb.AuthException catch (e) {
      return Left(_authFailure(e));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final res =
          await _dataSource.signUp(fullName.trim(), email.trim(), password);
      final authUser = res.user;

      if (authUser == null) {
        return const Left(ServerFailure('Sign up failed. Please try again.'));
      }

      // With email confirmation on, signUp returns a user but no session.
      // That's the normal path: the account exists, it just isn't usable
      // until the emailed code is verified. Returning null tells the caller
      // to send them to the OTP screen rather than into the app.
      if (res.session == null) return const Right(null);

      return Right(await _resolveUser(authUser, ensureProfile: true));
    } on sb.AuthException catch (e) {
      return Left(_authFailure(e));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, AppUser>> verifyOtp({
    required String email,
    required String code,
    required OtpPurpose purpose,
  }) async {
    try {
      final res = await _dataSource.verifyOtp(
        email: email.trim(),
        token: code.trim(),
        type: purpose == OtpPurpose.signup
            ? sb.OtpType.signup
            : sb.OtpType.recovery,
      );

      final authUser = res.user;
      if (authUser == null) {
        return const Left(ServerFailure('That code did not work.'));
      }

      return Right(await _resolveUser(authUser, ensureProfile: true));
    } on sb.AuthException catch (e) {
      return Left(_authFailure(e));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email.trim());
      return const Right(unit);
    } on sb.AuthException catch (e) {
      // Deliberately NOT surfacing "user not found": a caller that can tell
      // registered addresses from unregistered ones can harvest the user list.
      if (e.message.toLowerCase().contains('not found')) {
        return const Right(unit);
      }
      return Left(_authFailure(e));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String newPassword) async {
    try {
      await _dataSource.updatePassword(newPassword);
      return const Right(unit);
    } on sb.AuthException catch (e) {
      return Left(_authFailure(e));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final authUser = _dataSource.currentUser;
      if (authUser == null) return const Right(null);
      return Right(await _resolveUser(authUser));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _dataSource.onAuthStateChange.asyncMap((event) async {
      final authUser = event.session?.user;
      if (authUser == null) return null;
      // Session-only mapping here: this stream fires on every token refresh,
      // and a profile query on each one would be a round-trip for data that
      // rarely changes.
      return AppUserModel.fromAuthUser(authUser);
    });
  }

  // ── helpers ───────────────────────────────────────────────────

  /// Combines the auth session with the `public_users` row.
  ///
  /// When [ensureProfile] is set and no row exists yet, one is created — the
  /// first sign-in after registration is where the profile comes into being.
  Future<AppUser> _resolveUser(
    sb.User authUser, {
    bool ensureProfile = false,
  }) async {
    final fromAuth = AppUserModel.fromAuthUser(authUser);

    try {
      final row = await _dataSource.getProfile(authUser.id);

      if (row != null) return AppUserModel.fromProfileRow(row, authUser);

      if (ensureProfile) {
        await _dataSource.upsertProfile(
          userId: fromAuth.id,
          email: fromAuth.email,
          fullName: fromAuth.fullName,
        );
      }
    } catch (_) {
      // A profile that can't be read or written is not a reason to fail a
      // sign-in — the session is valid and the session-derived user is enough
      // to get into the app.
    }

    if (ensureProfile) {
      try {
        // Claim donations made as a guest with this email, so someone who
        // gave before signing up finds their history already there. The
        // website does the same on sign-in. Best-effort: failing to link
        // history must never block getting into the app.
        await _dataSource.linkGuestDonations();
      } catch (_) {}
    }

    return fromAuth;
  }

  /// Supabase's auth messages are written for developers. These are the ones
  /// a user actually sees, so they get plain wording.
  Failure _authFailure(sb.AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials')) {
      return const ServerFailure('Wrong email or password.');
    }
    if (msg.contains('email not confirmed')) {
      return const ServerFailure(
        'Please confirm your email first — check your inbox.',
      );
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return const ServerFailure('That email already has an account.');
    }
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return const ServerFailure('That code has expired. Request a new one.');
    }
    if (msg.contains('invalid') && msg.contains('token')) {
      return const ServerFailure('That code is not correct.');
    }
    if (msg.contains('password') && msg.contains('at least')) {
      return const ServerFailure('Password must be at least 6 characters.');
    }

    return ServerFailure(e.message);
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
