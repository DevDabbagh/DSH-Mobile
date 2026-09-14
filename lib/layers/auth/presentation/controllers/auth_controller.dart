import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/layers/auth/data/repositories/auth_repository_impl.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';

part 'auth_controller.g.dart';

/// Who is signed in, or null.
///
/// Named CurrentUser rather than AuthState because `supabase_flutter` exports
/// a type by that name, and two of them in one file is a trap for whoever
/// reads it next.
///
/// keepAlive because the whole app reads it — the router guard, the profile
/// screen, anything gated behind an account. It restores the persisted
/// session on first read, then follows Supabase's auth stream.
@Riverpod(keepAlive: true)
class CurrentUser extends _$CurrentUser {
  @override
  FutureOr<AppUser?> build() async {
    final repo = ref.read(authRepositoryProvider);

    // Sign-in, sign-out and token refresh all land here, which is what makes
    // the router guard react without anything having to tell it.
    final sub = repo.authStateChanges().listen((user) {
      state = AsyncData(user);
    });
    ref.onDispose(sub.cancel);

    final result = await repo.getCurrentUser();
    return result.fold((_) => null, (user) => user);
  }

  /// Re-reads the signed-in user, profile row included.
  ///
  /// The auth stream fires after a sign-in too, but it only carries the
  /// session — the name and role from `public_users` would be missing. The
  /// controller calls this once credentials are accepted.
  Future<void> refresh() async {
    final result = await ref.read(authRepositoryProvider).getCurrentUser();
    state = result.fold(
      (_) => const AsyncData(null),
      (user) => AsyncData(user),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

/// What the OTP screen needs to know but can't see.
///
/// Supabase verifies a code against an email address and a purpose, and the
/// OTP screen collects neither — the user typed their address on the screen
/// before. Rather than change screens built to the design, the flow that
/// sends the code parks the details here for the screen that confirms it.
class PendingVerification {
  final String email;
  final OtpPurpose purpose;

  const PendingVerification({required this.email, required this.purpose});
}

@Riverpod(keepAlive: true)
class PendingVerificationState extends _$PendingVerificationState {
  @override
  PendingVerification? build() => null;

  void start(String email, OtpPurpose purpose) =>
      state = PendingVerification(email: email, purpose: purpose);

  void clear() => state = null;
}

/// Drives the auth screens.
///
/// Method names and signatures match what the screens already call, so the
/// UI built to the design needed no changes to get real authentication.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  /// Reports a failure and answers whether it happened, so each method reads
  /// as a straight sequence instead of nesting its success path inside fold.
  bool _failed<T>(Either<Failure, T> result) {
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return true;
      },
      (_) => false,
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    final result =
        await ref.read(authRepositoryProvider).login(email, password);
    if (_failed(result)) return;

    await ref.read(currentUserProvider.notifier).refresh();
    state = const AsyncData(null);
  }

  /// Opens Google or Apple.
  ///
  /// Ends in [AsyncData] once the browser is open — which is NOT a sign-in.
  /// The session arrives later through the auth stream and the router guard
  /// picks it up, so the screens must not treat this as "you are in": doing
  /// so navigates away from the sign-in screen while the user is still
  /// choosing an account, and leaves them nowhere to come back to if they
  /// cancel.
  Future<void> signInWithProvider(SocialProvider provider) async {
    state = const AsyncLoading();

    final result =
        await ref.read(authRepositoryProvider).signInWithProvider(provider);
    if (_failed(result)) return;

    state = const AsyncData(null);
  }

  Future<void> register(String fullName, String email, String password) async {
    state = const AsyncLoading();

    final result = await ref.read(authRepositoryProvider).register(
          fullName,
          email,
          password,
          // The language the app is running in right now, taken at the moment
          // of sign-up. It decides what language the confirmation email is
          // written in — see AuthRemoteDataSource.signUp.
          locale: ref.read(localeControllerProvider).languageCode,
        );
    if (_failed(result)) return;

    // With email confirmation on, the account exists but isn't usable yet.
    // Remember the address so the OTP screen can verify against it.
    ref
        .read(pendingVerificationStateProvider.notifier)
        .start(email, OtpPurpose.signup);

    await ref.read(currentUserProvider.notifier).refresh();
    state = const AsyncData(null);
  }

  /// Verifies the emailed code.
  ///
  /// Takes only the code because that is all the OTP screen collects; the
  /// address and purpose come from [pendingVerificationStateProvider].
  Future<void> verifyOtp(String code) async {
    final pending = ref.read(pendingVerificationStateProvider);

    if (pending == null) {
      state = AsyncError(
        'Start again from sign up or password reset.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    final result = await ref.read(authRepositoryProvider).verifyOtp(
          email: pending.email,
          code: code,
          purpose: pending.purpose,
        );
    if (_failed(result)) return;

    // A recovery code has to stay usable until the new password is set, so
    // only a signup confirmation clears the pending state here.
    if (pending.purpose == OtpPurpose.signup) {
      ref.read(pendingVerificationStateProvider.notifier).clear();
    }

    await ref.read(currentUserProvider.notifier).refresh();
    state = const AsyncData(null);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();

    final result =
        await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    if (_failed(result)) return;

    ref
        .read(pendingVerificationStateProvider.notifier)
        .start(email, OtpPurpose.recovery);

    state = const AsyncData(null);
  }

  Future<void> resetPassword(String newPassword) async {
    state = const AsyncLoading();

    final result =
        await ref.read(authRepositoryProvider).updatePassword(newPassword);
    if (_failed(result)) return;

    ref.read(pendingVerificationStateProvider.notifier).clear();
    state = const AsyncData(null);
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(currentUserProvider.notifier).signOut();
    state = const AsyncData(null);
  }
}
