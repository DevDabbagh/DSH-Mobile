/// One row of the Academy library — Figma 2266:1099.
///
/// Thumbnail on the leading edge with a 2px teal→pink rule across its foot,
/// then the chip and delivery format, the title, who leads it and how long it
/// runs, the price, and a chevron.
///
/// HEIGHT IS NOT FIXED, AND THAT IS FROM THE FRAME
///
/// The frame draws two heights — 121 for a title that wraps to two lines,
/// 103 for one that does not (2266:1099 against 2266:1123). So the row sizes
/// to its content rather than clipping into a set box, and the thumbnail
/// stretches to match. Pinning it to one height would either crop the long
/// titles or leave a gap under the short ones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_atoms.dart';

class AcademyListCard extends StatelessWidget {
  final AcademyProgram program;
  final VoidCallback onTap;

  const AcademyListCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = academyPriceLabel(program);
    final radius = BorderRadius.circular(6.r);

    return Material(
      color: AppColors.cardSurface.withValues(alpha: 0.88),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.smoke.withValues(alpha: 0.10),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 80.w,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          url: program.thumbnailUrl,
                          thumb: true,
                        ),
                        // The brand rule along the foot of the still. Its own
                        // positioned bar rather than a bottom border on the
                        // image, because a border would be drawn outside the
                        // clip and disappear.
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: Container(
                            height: 2.h,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 0, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: AcademyTypeChip(
                                  label: academyTypeChip(program.type),
                                  small: true,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  academyFormatLabel(program.format),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.academyMuted,
                                    fontSize: 9.sp,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            program.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.smoke,
                              fontSize: 14.sp,
                              height: 1.29,
                              letterSpacing: -0.25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_byline.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Text(
                              _byline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.lightGrey,
                                fontSize: 11.sp,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          SizedBox(height: 3.h),
                          Text(
                            price.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: price.color,
                              fontSize: 11.sp,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14.w,
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Tiago Alexandre Pereira · 6 weeks" — and just the half that exists when
  /// the other is blank, rather than a stray separator.
  String get _byline {
    final parts = [program.whoLeads.trim(), program.duration.trim()]
        .where((s) => s.isNotEmpty);
    return parts.join(' · ');
  }
}
