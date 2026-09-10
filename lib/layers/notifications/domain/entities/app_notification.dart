import 'package:equatable/equatable.dart';

/// One notification as this person received it.
///
/// The multilingual columns have already been resolved to the reader's
/// language by the model, so nothing above this layer deals in JSONB.
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String imageUrl;

  /// In-app path the notification wants to open, or empty for none.
  final String route;

  final DateTime receivedAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.imageUrl = '',
    this.route = '',
    this.readAt,
  });

  bool get isUnread => readAt == null;
  bool get hasRoute => route.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, title, body, imageUrl, route, receivedAt, readAt];
}
