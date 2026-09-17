/// Google and Apple, side by side.
///
/// They used to be two full-width buttons stacked, each with "Continue with
/// …" written across it. That is 128 logical pixels of the sign-in screen
/// spent on two words repeated twice, and on a 5.4" phone it was the reason
/// the screen scrolled at all.
///
/// Side by side they cost 52, the wordmarks still identify them, and — the
/// part that actually matters — the email field and the password field are
/// both above the fold with the keyboard open.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';

class AuthSocialRow extends StatelessWidget {
  final ValueChanged<SocialProvider> onProvider;

  /// Greys both out while a sign-in is already in flight. Tapping Apple while
  /// Google's browser is opening starts two OAuth round trips, and whichever
  /// lands second overwrites the session from the first.
  final bool enabled;

  const AuthSocialRow({
    super.key,
    required this.onProvider,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialTile(
            label: 'Google',
            iconPath: 'assets/icons/ic_google.svg',
            // Google's mark is multi-coloured and must not be tinted — their
            // brand guidelines are explicit, and a white-filled version is
            // the single most common way apps get this wrong.
            tint: false,
            onTap: enabled ? () => onProvider(SocialProvider.google) : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SocialTile(
            label: 'Apple',
            iconPath: 'assets/icons/ic_apple_icon.svg',
            tint: true,
            onTap: enabled ? () => onProvider(SocialProvider.apple) : null,
          ),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool tint;
  final VoidCallback? onTap;

  const _SocialTile({
    required this.label,
    required this.iconPath,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final radius = BorderRadius.circular(14.r);

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 20.w,
                  height: 20.w,
                  colorFilter: tint
                      ? const ColorFilter.mode(
                          AppColors.smoke,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.smoke,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
