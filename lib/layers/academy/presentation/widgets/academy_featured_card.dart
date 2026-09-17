/// The featured programme — Figma 2266:1013.
///
/// A still with the type chip over it, then the title, the standfirst, the
/// person leading it beside their initials, the price, and a full-width
/// gradient button.
///
/// Which programme this is comes from the website: `AcademyListing.tsx` takes
/// `programs[0]` and filters the rest out of the grid below. The repository
/// returns them ordered, so "first" is the editor's choice rather than an
/// accident of the query.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_atoms.dart';

class AcademyFeaturedCard extends StatelessWidget {
  final AcademyProgram program;
  final VoidCallback onTap;

  const AcademyFeaturedCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = academyPriceLabel(program);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 195.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Not `thumb: true`: this is the largest image on the
                  // screen, and the ~600px copy would be visibly soft at
                  // 350×195 on a 3× display.
                  AppNetworkImage(url: program.thumbnailUrl),

                  // Darkens the top so the chip reads on a pale still, and
                  // stops at 55% so the lower half of the photograph is left
                  // alone — the frame's gradient, not a flat scrim.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.88),
                          Colors.black.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),

                  PositionedDirectional(
                    top: 10.h,
                    start: 10.w,
                    child: AcademyTypeChip(
                      label: academyTypeChip(program.type),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 17.sp,
                      height: 1.29,
                      letterSpacing: -0.35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (program.description.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      program.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.smoke.withValues(alpha: 0.42),
                        fontSize: 12.sp,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      if (program.whoLeads.trim().isNotEmpty) ...[
                        _Initials(name: program.whoLeads),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            program.whoLeads,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.mainBlue,
                              fontSize: 12.sp,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      SizedBox(width: 8.w),
                      Text(
                        price.text,
                        style: TextStyle(
                          color: price.color,
                          fontSize: 12.sp,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  AcademyGradientButton(
                    label: _actionFor(program.type),
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// You view a course and you open a toolkit. The entity's own doc comment
  /// makes this distinction — "you enrol in a course, you download a toolkit"
  /// — and this is the one place on the tab with room to honour it.
  String _actionFor(AcademyType type) => switch (type) {
        AcademyType.toolkit || AcademyType.resource => 'Open toolkit',
        AcademyType.mentorship => 'View mentorship',
        AcademyType.workshop => 'View workshop',
        AcademyType.course => 'View course',
      };
}

/// The gradient disc with someone's initials — the frame draws "TP" for Tiago
/// Alexandre Pereira, so it is first-and-last, not first-two.
class _Initials extends StatelessWidget {
  final String name;

  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.r,
      height: 24.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          color: AppColors.white,
          fontSize: 8.sp,
          height: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
