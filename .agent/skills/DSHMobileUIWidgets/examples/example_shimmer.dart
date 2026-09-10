import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';

class ExampleShimmer extends StatelessWidget {
  const ExampleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.mediumBackground,
      highlightColor: AppColors.lightGrey,
      child: Container(
        height: 80.h,
        width: double.infinity,
        margin: EdgeInsetsDirectional.symmetric(horizontal: AppDimensions.pagePadding.w),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius.r),
        ),
      ),
    );
  }
}
