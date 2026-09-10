import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/push/push_service.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/data/repositories/notification_repository_impl.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/app_notification.dart';

part 'notifications_controller.g.dart';

/// The inbox.
///
/// keepAlive, like the other content lists: returning to the screen should
/// show what was already loaded, not a spinner. `refresh()` is the explicit
/// way to go and look again — pull-to-refresh, and after a push arrives.
@Riverpod(keepAlive: true)
class NotificationsController extends _$NotificationsController {
  @override
  Future<List<AppNotification>> build() async {
    final result = await ref.watch(notificationRepositoryProvider).getInbox();
    return result.fold((failure) => throw failure.message, (items) => items);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(notificationRepositoryProvider).getInbox();
      return result.fold((failure) => throw failure.message, (items) => items);
    });
  }

  /// Marks everything read and updates the list in place.
  ///
  /// The local list is rewritten rather than refetched: the server has
  /// already been told, and a second round-trip would make the unread dots
  /// linger for a visible moment after the screen says they are read.
  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.every((n) => !n.isUnread)) return;

    await ref.read(notificationRepositoryProvider).markRead();

    final now = DateTime.now();
    state = AsyncData([
      for (final n in current)
        n.isUnread
            ? AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                imageUrl: n.imageUrl,
                route: n.route,
                receivedAt: n.receivedAt,
                readAt: now,
              )
            : n,
    ]);

    ref.invalidate(unreadCountProvider);
    await PushService.instance.clearBadge();
  }
}

/// The badge number.
///
/// Its own provider rather than `inbox.length` so the badge does not require
/// the inbox to have been loaded — it is read on screens that never open it.
@Riverpod(keepAlive: true)
Future<int> unreadCount(Ref ref) async {
  final result =
      await ref.watch(notificationRepositoryProvider).getUnreadCount();
  return result.fold((_) => 0, (count) => count);
}

/// Keeps the device row in step with the app.
///
/// Watched once, high in the widget tree. Three things on `push_devices` are
/// what the dashboard filters on — who owns the device, what language it
/// reads, and when it was last seen — and all three change while the app is
/// running. Registering only at launch would mean someone who signs in, or
/// switches to Arabic, keeps receiving as whoever and whatever they were
/// when the app started.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  @override
  Future<void> build() async {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final locale = ref.watch(localeControllerProvider).languageCode;

    if (user == null) {
      // Signed out — the device stays registered for broadcasts but stops
      // being attributable to anyone.
      await PushService.instance.releaseDevice();
      return;
    }

    await PushService.instance.registerDevice(locale: locale);

    // A push may have arrived while the app was closed, so the badge is
    // recounted whenever the session changes rather than trusted from
    // whatever the last screen saw.
    ref.invalidate(unreadCountProvider);
  }
}
