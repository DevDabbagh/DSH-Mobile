import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

/// Why an account is needed. Each case gets its own sentence, because
/// "you must sign in" tells someone nothing about what they gain by doing it.
enum SignInReason { enrol, donate, save, other }

/// Asks for an account at the moment an action needs one.
///
/// The app is browsable end to end as a guest; this is the gate, and it sits
/// on the action rather than on the route. Whoever calls it decides what
/// happens next — the dialog only reports whether the person chose to go and
/// sign in.
class SignInRequiredDialog extends StatelessWidget {
  final SignInReason reason;

  const SignInRequiredDialog({super.key, required this.reason});

  /// Shows the gate and, if the person accepts, sends them to the sign-in or
  /// registration screen.
  ///
  /// Returns true when they were sent to auth, so a caller can decide whether
  /// to retry the action after they come back.
  static Future<bool> show(
    BuildContext context, {
    SignInReason reason = SignInReason.other,
  }) async {
    final route = await showDialog<String>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.7),
      builder: (_) => SignInRequiredDialog(reason: reason),
    );

    if (route == null || !context.mounted) return false;
    context.push(route);
    return true;
  }

  String _message(AppLocalizations l10n) {
    switch (reason) {
      case SignInReason.enrol:
        return l10n.authRequiredEnroll;
      case SignInReason.donate:
        return l10n.authRequiredDonate;
      case SignInReason.save:
        return l10n.authRequiredSave;
      case SignInReason.other:
        return l10n.authRequiredGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_outline,
              size: 26.w,
              color: AppColors.mainPurple,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.authRequiredTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16.sp,
                height: 1.35,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 12.sp,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),
            // Sign in leads, because someone who already has an account is the
            // likelier case at a gate like this.
            _DialogButton(
              label: l10n.authSignIn,
              filled: true,
              onTap: () => Navigator.of(context).pop('/login'),
            ),
            SizedBox(height: 8.h),
            _DialogButton(
              label: l10n.authCreateAccount,
              onTap: () => Navigator.of(context).pop('/register'),
            ),
            SizedBox(height: 4.h),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.authCancel,
                style: TextStyle(
                  color: AppColors.mediumGrey,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(4.r),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.smoke.withValues(alpha: 0.16),
                  width: 0.8,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? AppColors.white : AppColors.smoke,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
