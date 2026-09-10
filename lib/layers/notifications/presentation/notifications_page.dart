import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/app_notification.dart';
import 'package:dsh_mobile/layers/notifications/presentation/controllers/notifications_controller.dart';

/// The inbox.
///
/// Everything that was ever pushed to this person, whether or not the banner
/// survived on their lock screen. Opening the screen marks it all read —
/// per-item read tracking would need a tap on each one, and nobody taps a
/// notification they have already seen just to clear a dot.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // After the first frame: markAllRead writes to a provider, and doing
    // that during a build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(currentUserProvider).valueOrNull != null;
    final inbox = ref.watch(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      appBar: AppBar(
        backgroundColor: AppColors.brandBlack,
        elevation: 0,
        title: Text(
          l10n.notificationsTitle,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: !signedIn
          // A guest has no inbox — there is nowhere to have sent anything.
          // Said plainly rather than shown as an empty list, which would
          // read as "you have no notifications" and be misleading.
          ? Center(
              child: EmptyStateWidget(
                icon: Icons.notifications_none,
                title: l10n.notificationsGuestTitle,
                subtitle: l10n.notificationsGuestBody,
                actionLabel: l10n.authSignIn,
                onAction: () => context.push('/login'),
              ),
            )
          : inbox.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorRetryWidget(
                message: error.toString(),
                onRetry: () => ref
                    .read(notificationsControllerProvider.notifier)
                    .refresh(),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: l10n.notificationsEmptyTitle,
                      subtitle: l10n.notificationsEmptyBody,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.mainBlue,
                  backgroundColor: AppColors.cardSurface,
                  onRefresh: () => ref
                      .read(notificationsControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: AppDimensions.pagePadding.w,
                      vertical: 12.h,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, i) => _NotificationCard(
                      notification: items[i],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsetsDirectional.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          // The unread accent is a border rather than a filled background:
          // filled cards on a near-black screen read as selected, not new.
          color: notification.isUnread
              ? AppColors.mainBlue.withValues(alpha: 0.35)
              : AppColors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: AppNetworkImage(
                url: notification.imageUrl,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (notification.isUnread) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mainBlue,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _relative(context, notification.receivedAt),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!notification.hasRoute) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => context.push(notification.route),
      child: card,
    );
  }

  /// Deliberately not intl's `timeago`: three more locale packages for a
  /// string that appears once per card.
  String _relative(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);

    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
    return '${when.day}/${when.month}/${when.year}';
  }
}
