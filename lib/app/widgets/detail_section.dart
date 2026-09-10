import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';

/// One block of a detail page: a small uppercase label, then content.
///
/// Every section on the film and studio detail screens is built from this, so
/// the label treatment and the spacing between blocks are defined once.
///
/// Returns nothing at all when [child] is null — that is how a page with a
/// half-filled record avoids rendering a heading over empty space.
class DetailSection extends StatelessWidget {
  final String label;
  final Widget? child;

  /// Set when the content runs edge to edge (a horizontal rail of stills, for
  /// example) and only the label should be inset.
  final bool bleed;

  /// The eyebrow's type, when a screen's frame specifies its own.
  ///
  /// Films and Studio genuinely differ here — Film Details draws the label at
  /// 9px, white 30%, 2.0 tracking; the Studio tab at 11px, smoke 35%, 1.76.
  /// They were collapsed onto one style once, which quietly changed every
  /// label on the film pages. The default is the film style because that is
  /// what most of these sections belong to.
  final TextStyle? labelStyle;

  /// Figma 2170:1277 — the section eyebrow on the film pages.
  static TextStyle filmLabel() => TextStyle(
        color: AppColors.white.withValues(alpha: 0.3),
        fontSize: 9.sp,
        height: 1.5,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      );

  /// Figma 2219:1458 — the section eyebrow on the studio tab.
  static TextStyle studioLabel() => TextStyle(
        color: AppColors.smoke.withValues(alpha: 0.35),
        fontSize: 11.sp,
        height: 1.5,
        letterSpacing: 1.76,
      );

  const DetailSection({
    super.key,
    required this.label,
    required this.child,
    this.bleed = false,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final content = child;
    if (content == null) return const SizedBox.shrink();

    final inset = EdgeInsets.symmetric(
      horizontal: AppDimensions.pagePadding.w,
    );

    return Padding(
      padding: EdgeInsets.only(top: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: inset,
            child: Text(
              label.toUpperCase(),
              style: labelStyle ?? filmLabel(),
            ),
          ),
          SizedBox(height: 12.h),
          if (bleed) content else Padding(padding: inset, child: content),
        ],
      ),
    );
  }
}

/// A label/value row, as used in the Credits block.
///
/// The label sits on the leading edge and the value on the trailing edge, so
/// it stays readable when the page is mirrored for Arabic.
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Figma 2170:1301 — 12px regular, white at 30%.
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.3),
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),
          SizedBox(width: 16.w),
          // Figma 2170:1303 — 12px medium, white at 75%.
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.75),
                fontSize: 12.sp,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small outlined pill used for themes ("Palestine", "Diaspora").
class DetailChip extends StatelessWidget {
  final String label;

  const DetailChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 0.6,
        ),
      ),
      // Figma 2170:1254 — 9px regular, white at 35%, 0.36 tracking.
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.35),
          fontSize: 9.sp,
          height: 1.5,
          letterSpacing: 0.36,
        ),
      ),
    );
  }
}
