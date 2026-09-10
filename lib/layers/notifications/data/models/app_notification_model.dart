import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/app_notification.dart';

/// Maps a joined `notification_recipients` row onto the domain entity.
///
/// The shape is the recipient row with the notification nested under it, as
/// the select in the datasource asks for:
///
///   { read_at, created_at, notifications: { id, title, body, … } }
class AppNotificationModel {
  const AppNotificationModel._();

  static AppNotification? fromRow(
    Map<String, dynamic> row,
    String locale, [
    String defaultLocale = 'en',
  ]) {
    // PostgREST returns the embedded row as an object, but as a *list* when
    // it cannot prove the relationship is to-one. Accept both rather than
    // let a schema-cache quirk empty the inbox.
    final raw = row['notifications'];
    final n = raw is List
        ? (raw.isEmpty ? null : raw.first as Map<String, dynamic>?)
        : raw as Map<String, dynamic>?;

    // The notification was deleted from the dashboard between the query and
    // the read. Dropped rather than rendered as an empty card.
    if (n == null) return null;

    final title = pickLang(n['title'], locale, defaultLocale);
    final body = pickLang(n['body'], locale, defaultLocale);
    if (title.trim().isEmpty && body.trim().isEmpty) return null;

    return AppNotification(
      id: n['id']?.toString() ?? '',
      title: title,
      body: body,
      imageUrl: resolveMediaUrl(n['image_url']?.toString() ?? ''),
      route: n['route']?.toString() ?? '',
      receivedAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      readAt: DateTime.tryParse(row['read_at']?.toString() ?? '')?.toLocal(),
    );
  }
}
