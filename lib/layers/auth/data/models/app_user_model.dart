import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';

/// Builds an [AppUser] from what Supabase gives us.
///
/// Two sources, because they arrive at different times: the auth session is
/// available the instant a user signs in, while their `public_users` row is a
/// second round-trip. Rather than block the UI on that, we build from the
/// session first and enrich once the profile lands.
class AppUserModel {
  const AppUserModel._();

  /// From the auth session alone.
  ///
  /// `full_name` is written into user_metadata at sign-up, so a freshly
  /// registered user still shows their real name before the profile row
  /// has been read.
  static AppUser fromAuthUser(User user) {
    final meta = user.userMetadata ?? const <String, dynamic>{};

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: (meta['full_name'] as String?)?.trim().isNotEmpty == true
          ? meta['full_name'] as String
          : (user.email?.split('@').first ?? 'User'),
      avatarUrl: meta['avatar_url'] as String?,
    );
  }

  /// From a `public_users` row, falling back to the session for anything the
  /// row is missing.
  static AppUser fromProfileRow(Map<String, dynamic> row, User authUser) {
    final base = fromAuthUser(authUser);

    final name = (row['full_name'] as String?)?.trim();
    final avatar = row['avatar_url'] as String?;
    final role = row['role'] as String?;

    return AppUser(
      id: base.id,
      email: (row['email'] as String?)?.trim().isNotEmpty == true
          ? row['email'] as String
          : base.email,
      fullName: name != null && name.isNotEmpty ? name : base.fullName,
      avatarUrl: avatar != null && avatar.isNotEmpty ? avatar : base.avatarUrl,
      role: role ?? base.role,
    );
  }
}
