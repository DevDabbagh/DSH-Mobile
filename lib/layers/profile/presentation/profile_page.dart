import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/widgets/language_picker_sheet.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/presentation/controllers/notifications_controller.dart';

/// The Profile tab, in both of the states the app actually has.
///
/// DSH is browsable without an account, so arriving here as a guest is normal
/// — not an error and not a redirect. The guest state offers the settings
/// that work without an account and explains what signing in adds; the
/// signed-in state shows the real person and the things tied to them.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 32.h),
              if (user == null)
                const _GuestHeader()
              else
                _UserHeader(user: user),
              SizedBox(height: 28.h),
              _Settings(user: user),
              SizedBox(height: 24.h),
              if (user != null) const _SignOutButton(),
              SizedBox(height: 110.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding.w,
      ),
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 32.w,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.profileGuestTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16.sp,
              height: 1.35,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l10n.profileGuestBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.sp,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _CtaButton(
                  label: l10n.authSignIn,
                  filled: true,
                  onTap: () => context.push('/login'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _CtaButton(
                  label: l10n.authCreateAccount,
                  onTap: () => context.push('/register'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final AppUser user;

  const _UserHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avatar = user.avatarUrl;

    return Column(
      children: [
        // Initials when there is no avatar — a generic silhouette would be
        // indistinguishable from the guest state directly above.
        Container(
          width: 80.w,
          height: 80.w,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: (avatar != null && avatar.isNotEmpty)
              ? AppNetworkImage(
                  url: avatar,
                  fit: BoxFit.cover,
                  // An avatar that fails to load should still say who this is.
                  fallback: _Initials(user: user),
                )
              : _Initials(user: user),
        ),
        SizedBox(height: 16.h),
        Text(
          user.fullName.trim().isEmpty ? l10n.profileMember : user.fullName,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          user.email,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final AppUser user;

  const _Initials({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 26.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(6.r),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.white.withValues(alpha: 0.14),
                  width: 0.8,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Settings extends ConsumerWidget {
  final AppUser? user;

  const _Settings({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = user != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account rows only exist once there is an account behind them.
          // Showing them greyed out to a guest would just be clutter they
          // cannot act on.
          if (signedIn) ...[
            _GroupLabel(label: l10n.profileAccount),
            _SettingsItem(
              icon: Icons.credit_card_outlined,
              title: l10n.profileBilling,
            ),
            _SettingsItem(
              icon: Icons.favorite_border_outlined,
              title: l10n.profileDonationSettings,
            ),
            // The inbox, not a preferences screen. Everything that was ever
            // pushed to this person lives here, whether or not the banner
            // survived on their lock screen.
            _SettingsItem(
              icon: Icons.notifications_none_outlined,
              title: l10n.profileNotifications,
              badgeCount: ref.watch(unreadCountProvider).valueOrNull ?? 0,
              onTap: () => context.push('/notifications'),
            ),
            SizedBox(height: 16.h),
          ],

          _GroupLabel(label: l10n.profileSettings),
          _SettingsItem(
            icon: Icons.language_outlined,
            title: l10n.profileLanguage,
            trailingText: languageLabel(
              ref.watch(localeControllerProvider).languageCode,
            ),
            onTap: () => LanguagePickerSheet.show(context),
          ),
          // No Appearance row: the app has one theme, so the switch had
          // nothing to switch between and an empty onChanged. A control that
          // does nothing is worse than an absent one — it reads as broken.
          // The `profileAppearance` string stays in the ARB files for when a
          // second theme exists.
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.profilePrivacy,
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: l10n.profileTerms,
          ),
          _SettingsItem(
            icon: Icons.help_outline,
            title: l10n.profileHelp,
          ),
          _SettingsItem(
            icon: Icons.info_outline,
            title: l10n.profileAbout,
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;

  const _GroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 10.sp,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton(
      onPressed: () async {
        // Signing out is easy to hit by accident and annoying to undo on a
        // phone, so it asks first.
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.profileSignOutConfirm,
              style: TextStyle(color: AppColors.white, fontSize: 15.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  l10n.authCancel,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  l10n.profileSignOut,
                  style: const TextStyle(color: AppColors.errorMain),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
        // No navigation afterwards: the app stays browsable signed out, and
        // this screen rebuilds itself into the guest state.
        await ref.read(currentUserProvider.notifier).signOut();
      },
      child: Text(
        l10n.profileSignOut,
        style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;

  /// Unread notifications. Zero draws nothing — an empty badge is noise.
  final int badgeCount;

  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.trailingText,
    this.badgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (badgeCount > 0) ...[
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: 7.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                // Past 99 the exact number stops mattering and starts
                // widening the row.
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          if (trailingText != null)
            Text(
              trailingText!,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
            )
          else
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20.w),
        ],
      ),
    );

    // Rows without an action stay plain, so nothing looks tappable until it
    // actually does something.
    if (onTap == null) return row;

    return InkWell(onTap: onTap, child: row);
  }
}
