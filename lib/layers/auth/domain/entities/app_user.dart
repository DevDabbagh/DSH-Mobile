import 'package:equatable/equatable.dart';

/// What the app knows about the signed-in person.
///
/// Named AppUser rather than User because `supabase_flutter` exports its own
/// `User`, and having two in scope makes every import ambiguous.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;

  /// 'guest' | 'registered' | 'subscriber' — mirrors `public_users.role`.
  final String role;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.role = 'registered',
  });

  bool get isSubscriber => role == 'subscriber';

  /// Initials for the avatar placeholder, e.g. "Ahmed Dabbagh" -> "AD".
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstLetter(parts.first);
    return _firstLetter(parts.first) + _firstLetter(parts.last);
  }

  static String _firstLetter(String s) =>
      s.isEmpty ? '' : s.substring(0, 1).toUpperCase();

  @override
  List<Object?> get props => [id, email, fullName, avatarUrl, role];
}
