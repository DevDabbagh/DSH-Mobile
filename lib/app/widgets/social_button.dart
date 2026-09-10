import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final String? iconPath;
  final IconData? iconData;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.text,
    this.iconPath,
    this.iconData,
    required this.onPressed,
  }) : assert(iconPath != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        minimumSize: Size(double.infinity, AppDimensions.buttonHeightMedium.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null)
            SvgPicture.asset(iconPath!, width: 24.w, height: 24.w)
          else if (iconData != null)
            Icon(iconData, size: 24.sp, color: AppColors.white),
          SizedBox(width: 12.w),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
