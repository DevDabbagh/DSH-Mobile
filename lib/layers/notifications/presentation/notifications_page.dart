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
import 'package:dsh_mobile/layers/notifications/presentation/widgets/newsletter_tab.dart';

/// Two things that both arrive unasked, kept apart.
///
/// **Notifications** is the push inbox: everything that was ever sent to this
/// person, whether or not the banner survived on their lock screen. Addressed
/// to one account, about something that just happened.
///
/// **Newsletter** is editorial: written once, sent to a list by email. Most
/// readers will have seen an issue in their inbox first, or chosen not to be
/// on the list at all — so it is not "mail you received", it is "what DSH
/// published", and it is readable whether or not you subscribe.
///
/// They were one screen before, which would have meant clearing the unread dot
/// marked an editorial issue as read, and a reader who never subscribed seeing
/// mail they were never sent.
class NotificationsPage extends ConsumerStatefulWidget {
  /// `newsletter` opens on the second tab. Anything else opens the inbox.
  final String initialTab;

  /// A campaign id from a push. The Newsletter tab opens its sheet once the
  /// archive has loaded.
  final String openIssueId;

  const NotificationsPage({
    super.key,
    this.initialTab = '',
    this.openIssueId = '',
  });

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

    // A newsletter push arrives while the app may be anywhere, including cold
    // — so the tab is chosen here rather than by a controller somebody has to
    // remember to drive.
    final startOnNewsletter = widget.initialTab == 'newsletter' ||
        widget.openIssueId.trim().isNotEmpty;

    return DefaultTabController(
      length: 2,
      initialIndex: startOnNewsletter ? 1 : 0,
      child: Scaffold(
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.h),
            child: Align(
              // Two tabs stretched across a phone puts each label in the
              // middle of half a screen, miles from the other. Left-aligned
              // and only as wide as the words is how a two-tab strip is meant
              // to sit.
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: AppDimensions.pagePadding.w - 16,
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.mainBlue,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: l10n.notificationsTitle),
                    const Tab(text: 'Newsletter'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const _InboxTab(),
            NewsletterTab(openIssueId: widget.openIssueId),
          ],
        ),
      ),
    );
  }
}

/// The push inbox — what this screen was before the split.
class _InboxTab extends ConsumerWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(currentUserProvider).valueOrNull != null;
    final inbox = ref.watch(notificationsControllerProvider);

    // A guest has no inbox — there is nowhere to have sent anything. Said
    // plainly rather than shown as an empty list, which would read as "you
    // have no notifications" and be misleading.
    //
    // The Newsletter tab beside it deliberately does NOT do this: past issues
    // are public, so a guest can read them and is only asked to sign in for
    // the part that needs an account.
    if (!signedIn) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.notifications_none,
          title: l10n.notificationsGuestTitle,
          subtitle: l10n.notificationsGuestBody,
          actionLabel: l10n.authSignIn,
          onAction: () => context.push('/login'),
        ),
      );
    }

    return inbox.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.mainBlue),
      ),
      error: (error, _) => ErrorRetryWidget(
        message: error.toString(),
        onRetry: () =>
            ref.read(notificationsControllerProvider.notifier).refresh(),
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
          onRefresh: () =>
              ref.read(notificationsControllerProvider.notifier).refresh(),
          child: ListView.separated(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppDimensions.pagePadding.w,
              vertical: 12.h,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, i) =>
                _NotificationCard(notification: items[i]),
          ),
        );
      },
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
                thumb: true,
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
