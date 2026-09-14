import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'auth_remote_datasource.g.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// `full_name` goes into user_metadata so it survives until the profile row
  /// exists — a user who has signed up but not confirmed their email has no
  /// `public_users` row yet.
  ///
  /// `locale` is there for the same reason and one more: the confirmation
  /// email is composed by an Edge Function that runs before any profile row
  /// exists, and metadata is the only thing it can see. Without it, someone
  /// who used the app in Portuguese is welcomed in English by the very first
  /// message DSH ever sends them.
  Future<AuthResponse> signUp(
    String fullName,
    String email,
    String password, {
    required String locale,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'locale': locale},
    );
  }

  /// Where the OAuth provider sends the browser once the user has approved.
  ///
  /// A custom scheme rather than an https link: the app has no website of its
  /// own to land on, and this is what Android's intent filter and iOS's
  /// `CFBundleURLSchemes` entry are registered against. It must be listed in
  /// Supabase under Authentication → URL Configuration → Redirect URLs, or the
  /// provider refuses the round trip.
  static const oauthRedirect = 'com.devdabbagh.dsh://login-callback/';

  /// Hands off to Google or Apple.
  ///
  /// Returns as soon as the browser is open — NOT when the user is signed in.
  /// The session arrives later, through [onAuthStateChange], because the app
  /// is resumed by the redirect rather than by this call returning. So there
  /// is nothing useful to await here, and a caller that waits for a user is
  /// waiting for something that will never come back this way.
  Future<bool> signInWithProvider(OAuthProvider provider) {
    return _client.auth.signInWithOAuth(
      provider,
      redirectTo: oauthRedirect,
      // The provider's own page in a Custom Tab / SFSafariViewController,
      // which is what both Google and Apple require — an embedded webview is
      // rejected by Google as a possible credential-phishing surface.
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) {
    return _client.auth.verifyOTP(email: email, token: token, type: type);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _client.auth.signOut();

  /// The caller's own `public_users` row, or null if it hasn't been created.
  ///
  /// `maybeSingle` rather than `single`: a missing row is expected right after
  /// sign-up, not an error.
  Future<Map<String, dynamic>?> getProfile(String userId) {
    return _client.from('public_users').select().eq('id', userId).maybeSingle();
  }

  /// Creates the profile row on first sign-in. Idempotent via upsert, so a
  /// second call after a re-login doesn't fail on the primary key.
  Future<void> upsertProfile({
    required String userId,
    required String email,
    required String fullName,
  }) {
    return _client.from('public_users').upsert({
      'id': userId,
      'email': email,
      'full_name': fullName,
    });
  }

  /// Attaches donations made as a guest with this same email address.
  ///
  /// Someone can donate before they have an account; without this their
  /// history looks empty once they sign up. The website calls the same
  /// function on sign-in (AuthContext), so both surfaces behave alike.
  ///
  /// Takes no arguments by design — it claims only rows matching the
  /// caller's own verified email, so it cannot be pointed at anyone else
  /// (migration 020).
  Future<void> linkGuestDonations() => _client.rpc('link_my_donations');
}

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) =>
    AuthRemoteDataSource(ref.read(supabaseClientProvider));
