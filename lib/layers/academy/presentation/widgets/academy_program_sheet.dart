/// What a programme card opens.
///
/// WHY A SHEET AND NOT A SCREEN
///
/// There is no Academy details route. `/academy/:slug` does not exist, and
/// the global search screen says so in a comment of its own — a course result
/// there opens the tab rather than the course. The frame this tab was built
/// from (2266:806) does not draw a details screen either.
///
/// So the choice was between a card that looks tappable and is not, and
/// showing what the app already holds. Every field below is on
/// [AcademyProgram] and comes from the same dashboard row the website reads,
/// so this is real content rather than a placeholder standing in for a screen.
///
/// WHEN THE DETAILS SCREEN ARRIVES
///
/// Both cards take an `onTap`, and the page is the only place that decides
/// what it does. Pointing them at `context.push('/academy/$slug')` is a
/// one-line change in `academy_page.dart`; nothing here needs to move.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_atoms.dart';

class AcademyProgramSheet extends StatelessWidget {
  final AcademyProgram program;

  const AcademyProgramSheet({super.key, required this.program});

  static Future<void> show(BuildContext context, AcademyProgram program) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AcademyProgramSheet(program: program),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = academyPriceLabel(program);

    return DraggableScrollableSheet(
      // Tall enough to show the still and the first facts without a drag,
      // short enough that the tab behind it is still visible — so the sheet
      // reads as something over the page rather than as a new screen.
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.deepBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.smoke.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (program.thumbnailUrl.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding.w,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppNetworkImage(url: program.thumbnailUrl),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding.w,
                18.h,
                AppDimensions.pagePadding.w,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AcademyTypeChip(
                        label: academyTypeChip(program.type),
                        small: true,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        academyFormatLabel(program.format),
                        style: TextStyle(
                          color: AppColors.academyMuted,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price.text,
                        style: TextStyle(
                          color: price.color,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    program.title,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 20.sp,
                      height: 1.25,
                      letterSpacing: -0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (program.description.trim().isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      program.description,
                      style: TextStyle(
                        color: AppColors.smoke.withValues(alpha: 0.55),
                        fontSize: 13.sp,
                        height: 1.55,
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  _Fact(label: 'Led by', value: program.whoLeads),
                  _Fact(label: 'Who it is for', value: program.whoItsFor),
                  _Fact(label: 'Runs for', value: program.duration),
                  _Fact(label: 'Dates', value: program.dates),
                  _Fact(label: 'How to join', value: program.howToJoin),
                  _Fact(
                    label: 'Scholarships',
                    value: program.scholarshipNote,
                  ),
                  _Fact(
                    label: program.certification.label,
                    value: program.certification.value,
                  ),
                  if (program.lessons.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      'What it covers'.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.smoke.withValues(alpha: 0.35),
                        fontSize: 10.sp,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    for (final lesson in program.lessons)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: Container(
                                width: 4.r,
                                height: 4.r,
                                decoration: const BoxDecoration(
                                  color: AppColors.mainBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: TextStyle(
                                  color:
                                      AppColors.smoke.withValues(alpha: 0.75),
                                  fontSize: 12.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            if (lesson.hasDuration) ...[
                              SizedBox(width: 10.w),
                              Text(
                                lesson.duration,
                                style: TextStyle(
                                  color: AppColors.academyMuted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label/value pair, and nothing at all when the editor left it blank —
/// a heading over an empty line is how a half-filled record reads as a bug.
class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.smoke.withValues(alpha: 0.35),
              fontSize: 10.sp,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: AppColors.smoke.withValues(alpha: 0.75),
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
