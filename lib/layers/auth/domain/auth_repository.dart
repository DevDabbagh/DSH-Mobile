import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';

/// Which flow an emailed code belongs to.
///
/// Supabase verifies a signup code and a password-recovery code through the
/// same endpoint but a different `type`, so the OTP screen has to carry this
/// through from wherever the user started.
enum OtpPurpose { signup, recovery }

/// The third-party sign-ins offered on the auth screens.
///
/// Its own enum rather than Supabase's `OAuthProvider`, which lists twenty
/// providers we do not support — the domain layer should say what this app
/// actually offers, and the data layer maps it.
enum SocialProvider { google, apple }

abstract class AuthRepository {
  Future<Either<Failure, AppUser>> login(String email, String password);

  /// Opens the provider's sign-in page.
  ///
  /// Succeeds when the browser opens, not when the user signs in — the
  /// session arrives afterwards through [authStateChanges], because the app
  /// is resumed by the redirect. So callers show no success state here; the
  /// router guard reacts on its own once the session lands.
  Future<Either<Failure, Unit>> signInWithProvider(SocialProvider provider);

  /// [locale] is stored on the account so the confirmation email — composed
  /// before any profile row exists — can be written in the language the
  /// person just signed up in.
  Future<Either<Failure, AppUser?>> register(
    String fullName,
    String email,
    String password, {
    required String locale,
  });

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

  /// Sends the code again for whichever flow the user is in.
  ///
  /// Supabase rate-limits this server-side and answers with "For security
  /// purposes, you can only request this after N seconds" — which the OTP
  /// screen surfaces rather than hides, because a user who has been told to
  /// wait 43 seconds stops tapping.
  Future<Either<Failure, Unit>> resendOtp({
    required String email,
    required OtpPurpose purpose,
  });

  /// Sets a new password for the currently authenticated session.
  Future<Either<Failure, Unit>> updatePassword(String newPassword);

  Future<Either<Failure, Unit>> logout();

  /// The user for the restored session, or null when signed out.
  Future<Either<Failure, AppUser?>> getCurrentUser();

  /// Emits on sign-in, sign-out and token refresh. Drives the router guard.
  Stream<AppUser?> authStateChanges();
}
