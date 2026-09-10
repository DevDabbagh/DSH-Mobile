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
  Future<AuthResponse> signUp(
    String fullName,
    String email,
    String password,
  ) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
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
