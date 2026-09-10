import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  /// This person's inbox, newest first.
  ///
  /// An empty list is a normal answer — most people have received nothing
  /// yet — and a guest, who has no inbox at all, gets one too rather than
  /// an error.
  Future<Either<Failure, List<AppNotification>>> getInbox();

  /// How many are unread. Separate from [getInbox] because the tab badge
  /// needs the number without the rows.
  Future<Either<Failure, int>> getUnreadCount();

  /// Marks everything read, or just [ids] when given.
  Future<Either<Failure, int>> markRead({List<String>? ids});
}
