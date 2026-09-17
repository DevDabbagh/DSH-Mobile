/// The Newsletter half of the inbox screen.
///
/// WHY THIS IS A SEPARATE TAB AND NOT MORE CARDS IN THE INBOX
///
/// They are different things that happen to both arrive unasked. A push
/// notification is addressed to one person, lands on their lock screen, and
/// is about something that just happened. A newsletter issue is written once,
/// sent to everyone on the list, and arrives by email — most readers will have
/// seen it there first, or chosen not to be on the list at all.
///
/// Mixing them would mean an inbox where clearing the dot marks an editorial
/// issue as read, and where a reader who is not subscribed sees mail they
/// never received. Two tabs keeps "what was sent to me" and "what DSH
/// published" apart, which is what the website already does.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';
import 'package:dsh_mobile/layers/notifications/domain/repositories/newsletter_repository.dart';
import 'package:dsh_mobile/layers/notifications/presentation/controllers/newsletter_controller.dart';
import 'package:dsh_mobile/layers/notifications/presentation/widgets/newsletter_issue_sheet.dart';

class NewsletterTab extends ConsumerStatefulWidget {
  /// A campaign id from a push notification. Opened once, as soon as the
  /// archive containing it has loaded.
  final String openIssueId;

  const NewsletterTab({super.key, this.openIssueId = ''});

  @override
  ConsumerState<NewsletterTab> createState() => _NewsletterTabState();
}

class _NewsletterTabState extends ConsumerState<NewsletterTab> {
  /// So the sheet is opened once and not again on every rebuild — and not
  /// again when the reader closes it, which is the version of this bug that
  /// traps someone in a sheet they cannot dismiss.
  bool _opened = false;

  /// The tap that brought them here has to wait for the archive: the push
  /// carries an id, and the issue behind it is not in memory yet.
  void _openRequestedIssue(List<NewsletterIssue> issues) {
    final wanted = widget.openIssueId.trim();
    if (_opened || wanted.isEmpty) return;

    final match = issues.where((i) => i.id == wanted);
    if (match.isEmpty) return;

    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NewsletterIssueSheet.show(context, match.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final archive = ref.watch(newsletterArchiveProvider);
    archive.whenData(_openRequestedIssue);

    return RefreshIndicator(
      color: AppColors.mainBlue,
      backgroundColor: AppColors.cardSurface,
      onRefresh: () async {
        ref.invalidate(newsletterSubscriptionProvider);
        await ref.read(newsletterArchiveProvider.notifier).refresh();
      },
      child: archive.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 80.h),
            ErrorRetryWidget(
              message: error.toString(),
              onRetry: () =>
                  ref.read(newsletterArchiveProvider.notifier).refresh(),
            ),
          ],
        ),
        data: (issues) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            14.h,
            AppDimensions.pagePadding.w,
            32.h,
          ),
          children: [
            const _SubscriptionPanel(),
            SizedBox(height: 22.h),
            if (issues.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: EmptyStateWidget(
                  icon: Icons.mail_outline,
                  title: 'No issues yet',
                  subtitle:
                      'When DSH sends its first newsletter, it will be here '
                      'to read — whether or not you are on the list.',
                ),
              )
            else ...[
              Text(
                'Past issues'.toUpperCase(),
                style: TextStyle(
                  color: AppColors.smoke.withValues(alpha: 0.35),
                  fontSize: 10.sp,
                  height: 1.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              for (final issue in issues) ...[
                _IssueCard(issue: issue),
                SizedBox(height: 10.h),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Am I on the list, and the one action that follows from the answer.
class _SubscriptionPanel extends ConsumerStatefulWidget {
  const _SubscriptionPanel();

  @override
  ConsumerState<_SubscriptionPanel> createState() => _SubscriptionPanelState();
}

class _SubscriptionPanelState extends ConsumerState<_SubscriptionPanel> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.cardSurface,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final status = ref.watch(newsletterSubscriptionProvider).valueOrNull ??
        NewsletterStatus.none;

    // A guest has no verified address, and asking one to type an email here
    // would create a list entry with no account behind it — which the website
    // footer already does better, and which this screen cannot then manage.
    if (user == null) {
      return _Panel(
        title: 'The DSH newsletter',
        body: 'Sign in to join the list and manage it from here.',
        action: _Action(
          label: l10n.authSignIn,
          onTap: () => context.push('/login'),
        ),
      );
    }

    final (title, body, action) = switch (status) {
      NewsletterStatus.subscribed => (
          'You are on the list',
          'New issues arrive at ${user.email}.',
          _Action(
            label: 'Unsubscribe',
            quiet: true,
            onTap: () => _run(() => ref
                .read(newsletterSubscriptionProvider.notifier)
                .unsubscribe()),
          ),
        ),
      NewsletterStatus.pending => (
          'One step left',
          // The honest state, and the one most likely to be hit: migration
          // 043 notes that no confirmation email has ever been sent, so
          // everyone who signed up before that is stranded here.
          'We sent a confirmation to ${user.email}. You are not on the list '
              'until you open it and confirm.',
          _Action(
            label: 'Send it again',
            quiet: true,
            onTap: () => _run(() => ref
                .read(newsletterSubscriptionProvider.notifier)
                .subscribe(user.email)),
          ),
        ),
      NewsletterStatus.bounced || NewsletterStatus.complained => (
          'We have stopped emailing you',
          // Deliberately no button. Re-subscribing an address that bounced or
          // reported us as spam is what gets a sending domain filtered — and
          // password resets leave from the same domain. The RPC refuses too;
          // this stops the app offering a control that can only fail.
          'Email to ${user.email} was returned or reported. Write to us if '
              'that was not deliberate.',
          null,
        ),
      _ => (
          'The DSH newsletter',
          'New films, open calls and workshops — a few times a month, to '
              '${user.email}.',
          _Action(
            label: 'Subscribe',
            onTap: () => _run(() => ref
                .read(newsletterSubscriptionProvider.notifier)
                .subscribe(user.email)),
          ),
        ),
    };

    return _Panel(
      title: title,
      body: body,
      action: action,
      busy: _busy,
    );
  }
}

class _Action {
  final String label;
  final VoidCallback onTap;

  /// Draws as an outline rather than the brand gradient. Leaving the list is
  /// something a reader is entitled to do easily and should not be invited to
  /// do by the loudest control on the screen.
  final bool quiet;

  const _Action({required this.label, required this.onTap, this.quiet = false});
}

class _Panel extends StatelessWidget {
  final String title;
  final String body;
  final _Action? action;
  final bool busy;

  const _Panel({
    required this.title,
    required this.body,
    this.action,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final act = action;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14.sp,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
          if (act != null) ...[
            SizedBox(height: 14.h),
            if (busy)
              SizedBox(
                height: 36.h,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainBlue,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: act.onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 36.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: act.quiet ? null : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8.r),
                    border: act.quiet
                        ? Border.all(
                            color: AppColors.white.withValues(alpha: 0.14),
                          )
                        : null,
                  ),
                  child: Text(
                    act.label,
                    style: TextStyle(
                      color: act.quiet ? AppColors.textSecondary : Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final NewsletterIssue issue;

  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final teaser = issue.teaser;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => NewsletterIssueSheet.show(context, issue),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (issue.category.trim().isNotEmpty) ...[
                  Text(
                    issue.category.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.mainBlue,
                      fontSize: 9.sp,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  _date(issue.sentAt),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              issue.subject,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13.sp,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (teaser.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                teaser,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// An absolute date, not "3 days ago". The inbox uses relative time because
  /// a notification is about something that just happened; an issue of a
  /// newsletter is dated, and "12 Aug 2026" is how anyone refers to one.
  String _date(DateTime when) =>
      '${when.day} ${_months[when.month - 1]} ${when.year}';
}
