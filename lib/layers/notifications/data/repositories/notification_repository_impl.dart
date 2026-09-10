import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:dsh_mobile/layers/notifications/data/models/app_notification_model.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/app_notification.dart';
import 'package:dsh_mobile/layers/notifications/domain/repositories/notification_repository.dart';

part 'notification_repository_impl.g.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _dataSource;
  final String _locale;

  /// False for a guest. Every method short-circuits on it rather than
  /// querying: RLS would return an empty set anyway, so the round-trip is
  /// pure latency on a screen that has nothing to show.
  final bool _signedIn;

  NotificationRepositoryImpl(this._dataSource, this._locale, this._signedIn);

  @override
  Future<Either<Failure, List<AppNotification>>> getInbox() async {
    if (!_signedIn) return const Right([]);

    try {
      final rows = await _dataSource.getInbox();

      final items = rows
          .map((r) => AppNotificationModel.fromRow(
                r,
                _locale,
                SupabaseConfig.defaultLocale,
              ))
          .whereType<AppNotification>()
          .toList();

      return Right(items);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    if (!_signedIn) return const Right(0);

    try {
      return Right(await _dataSource.getUnreadCount());
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, int>> markRead({List<String>? ids}) async {
    if (!_signedIn) return const Right(0);

    try {
      return Right(await _dataSource.markRead(ids));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  // watch on both: switching language re-resolves the stored JSONB, and
  // signing in or out changes whose inbox this is. Either with `read` and
  // the screen keeps showing the previous person's notifications.
  final locale = ref.watch(localeControllerProvider).languageCode;
  final signedIn = ref.watch(currentUserProvider).valueOrNull != null;

  return NotificationRepositoryImpl(
    ref.read(notificationRemoteDataSourceProvider),
    locale,
    signedIn,
  );
}
