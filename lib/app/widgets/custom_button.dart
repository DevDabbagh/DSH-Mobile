import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';

enum CustomButtonType {
  primaryPink,
  primaryBlue,
  primaryGrey,
  gradientFill,
  gradientOutline,
}

enum CustomButtonSize {
  large,
  medium,
  small,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonType type;
  final CustomButtonSize size;
  final double? width;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = CustomButtonType.gradientFill,
    this.size = CustomButtonSize.large,
    this.width,
    this.icon,
  });

  double get _buttonHeight {
    switch (size) {
      case CustomButtonSize.large:
        return AppDimensions.buttonHeightLarge.h;
      case CustomButtonSize.medium:
        return AppDimensions.buttonHeightMedium.h;
      case CustomButtonSize.small:
        return AppDimensions.buttonHeightSmall.h;
    }
  }

  TextStyle? _textStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    switch (size) {
      case CustomButtonSize.large:
        return textTheme.labelLarge;
      case CustomButtonSize.medium:
        return textTheme.labelMedium;
      case CustomButtonSize.small:
        return textTheme.labelSmall;
    }
  }

  Color _getSolidColor() {
    switch (type) {
      case CustomButtonType.primaryPink:
        return AppColors.mainPurple;
      case CustomButtonType.primaryBlue:
        return AppColors.mainBlue;
      case CustomButtonType.primaryGrey:
        return AppColors.mediumGrey;
      default:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (type == CustomButtonType.gradientOutline) {
      return AppColors.white;
    }
    return AppColors.white;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final bool isGradient = type == CustomButtonType.gradientFill;
    final bool isOutline = type == CustomButtonType.gradientOutline;

    BoxDecoration decoration;

    if (isDisabled) {
      decoration = BoxDecoration(
        color: AppColors.mediumGrey, // Disabled color
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
      );
    } else if (isGradient) {
      decoration = BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
      );
    } else if (isOutline) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
        border: Border.all(color: Colors.transparent),
      );
    } else {
      decoration = BoxDecoration(
        color: _getSolidColor(),
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
      );
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(context)?.copyWith(
              color: isDisabled ? AppColors.lightGrey : _getTextColor(),
            ),
          ),
        ),
      ],
    );

    if (isLoading) {
      content = SizedBox(
        width: 24.w,
        height: 24.w,
        child: CircularProgressIndicator(
          color: isDisabled ? AppColors.lightGrey : _getTextColor(),
          strokeWidth: 2,
        ),
      );
    }

    Widget buttonCore = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
        child: Container(
          width: width,
          height: _buttonHeight,
          padding:
              EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isOutline && !isDisabled) {
      return Container(
        width: width,
        height: _buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(1.5.r), // Border width
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBackground, // Inner background
              borderRadius:
                  BorderRadius.circular((AppDimensions.buttonRadius - 1.5).r),
            ),
            child: buttonCore,
          ),
        ),
      );
    }

    return Ink(
      decoration: decoration,
      child: buttonCore,
    );
  }
}
