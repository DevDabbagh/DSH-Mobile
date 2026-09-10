import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';

/// Which flow an emailed code belongs to.
///
/// Supabase verifies a signup code and a password-recovery code through the
/// same endpoint but a different `type`, so the OTP screen has to carry this
/// through from wherever the user started.
enum OtpPurpose { signup, recovery }

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> login(String email, String password);

  Future<Either<Failure, AppUser?>> register(
    String fullName,
    String email,
    String password,
  );

  /// Confirms an emailed code. Returns the signed-in user on success.
  Future<Either<Failure, AppUser>> verifyOtp({
    required String email,
    required String code,
    required OtpPurpose purpose,
  });

  /// Sends a password-recovery email.
  ///
  /// Always reports success, even for an address with no account — telling a
  /// caller which emails are registered turns this into a way to enumerate
  /// users.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Sets a new password for the currently authenticated session.
  Future<Either<Failure, Unit>> updatePassword(String newPassword);

  Future<Either<Failure, Unit>> logout();

  /// The user for the restored session, or null when signed out.
  Future<Either<Failure, AppUser?>> getCurrentUser();

  /// Emits on sign-in, sign-out and token refresh. Drives the router guard.
  Stream<AppUser?> authStateChanges();
}
