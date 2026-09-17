/// "Five ways in" — Figma 2266:953.
///
/// An eyebrow, a headline, "Free by principle." in teal, then five teal-ringed
/// circles naming the kinds of thing the Academy runs.
///
/// THE CIRCLES ARE FILTERS, NOT DECORATION
///
/// The frame draws them as buttons and says nothing about what they do. The
/// honest reading is the one that makes them worth tapping: each names an
/// [AcademyType], the library below already filters by type, so tapping one
/// sets that filter and scrolls to the list. Otherwise this is a row of five
/// things that look pressable and are not, directly above a row of chips that
/// do the same job in words.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

/// The five, in the frame's order. `resource` is absent on purpose — it is
/// the same idea as `toolkit` (see `academyTypeLabel`), and two circles
/// meaning one thing is how a row of five becomes a row of six that repeats
/// itself.
const _kWaysIn = <({AcademyType type, IconData icon, String label})>[
  (type: AcademyType.course, icon: Icons.menu_book_outlined, label: 'Courses'),
  (type: AcademyType.toolkit, icon: Icons.build_outlined, label: 'Toolkits'),
  (type: AcademyType.workshop, icon: Icons.groups_outlined, label: 'Workshops'),
  (
    type: AcademyType.resource,
    icon: Icons.mic_none_outlined,
    label: 'Community learning'
  ),
  (
    type: AcademyType.mentorship,
    icon: Icons.favorite_border,
    label: 'Mentorships'
  ),
];

class AcademyWaysIn extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String note;

  /// Which one is currently the library's type filter, so the row reflects
  /// the state it sets rather than looking inert once used.
  final AcademyType? selected;

  final ValueChanged<AcademyType> onSelect;

  const AcademyWaysIn({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.note,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final inset = EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w);

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.smoke.withValues(alpha: 0.35),
                    fontSize: 10.sp,
                    height: 1.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  headline,
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 20.sp,
                    height: 1.3,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  note,
                  style: TextStyle(
                    color: AppColors.mainBlue,
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Scrollable rather than five fixed slots: at 393 wide the five fit,
          // but "Community learning" is two lines and a larger text scale
          // overflows the row. This bends instead of breaking.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: inset,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final way in _kWaysIn) ...[
                  _WayIn(
                    icon: way.icon,
                    label: way.label,
                    selected: selected == way.type,
                    onTap: () => onSelect(way.type),
                  ),
                  if (way != _kWaysIn.last) SizedBox(width: 14.w),
                ],
              ],
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _WayIn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _WayIn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60.w,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54.r,
              height: 54.r,
              decoration: BoxDecoration(
                color: AppColors.mainBlue
                    .withValues(alpha: selected ? 0.18 : 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.mainBlue
                      .withValues(alpha: selected ? 0.55 : 0.18),
                  width: selected ? 1.2 : 0.6,
                ),
              ),
              child: Icon(icon, size: 22.w, color: AppColors.mainBlue),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: selected
                    ? AppColors.smoke
                    : AppColors.smoke.withValues(alpha: 0.4),
                fontSize: 10.sp,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
