import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

/// How much of a library a tab shows before handing over to its "all" screen.
///
/// The Films and Studio tabs are front pages: a hero, a featured piece, and a
/// taste of the library. Before this cap each printed its entire library
/// underneath, so a healthy tab was one scroll several screens long that
/// ended nowhere in particular — and got worse with every publish.
///
/// Four is the number that still shows the *shape* of the list: enough rows
/// to read as a list rather than as a couple of stray cards.
const int kLibraryPreview = 4;

/// The full-width "See all" under a capped list.
///
/// Repeats the "See all" in the section heading on purpose: after four cards
/// the heading is off the top of the screen, and the reader is at the bottom
/// of a list wondering whether that is all there is.
class SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const SeeAllButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        14.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: AppColors.smoke.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.seeAll,
                style: TextStyle(
                  color: AppColors.smoke,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.arrow_forward, color: AppColors.smoke, size: 14.w),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the filters leave nothing.
///
/// Carries the way out with it. An empty list under a filter bar, with no
/// clear button, is a dead end a reader has to reason their way back from —
/// and the most common conclusion is that the content is gone.
class NoFilterMatches extends StatelessWidget {
  final VoidCallback onClear;

  const NoFilterMatches({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 44.h),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            color: AppColors.mediumGrey,
            size: 30.w,
          ),
          SizedBox(height: 14.h),
          Text(
            l10n.filterNoResults,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightGrey, fontSize: 13.sp),
          ),
          SizedBox(height: 4.h),
          TextButton(
            onPressed: onClear,
            child: Text(
              l10n.filterClearFilters,
              style: TextStyle(color: AppColors.mainBlue, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
