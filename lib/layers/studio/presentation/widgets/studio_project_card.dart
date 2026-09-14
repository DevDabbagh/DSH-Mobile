import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_format_label.dart';

/// A studio project: still on the leading edge, then format, title,
/// description and a "View episodes" button.
///
/// Used both for the single featured project and for the cards in the
/// library rail, which is why the width is passed in rather than fixed.
class StudioProjectCard extends StatelessWidget {
  final StudioProject project;
  final double width;

  /// The featured card carries the gradient button; library cards are
  /// outlined, so the eye lands on the featured one first.
  final bool emphasised;
  final VoidCallback? onTap;

  // Figma 2219:1512 / 2219:1513.
  static const double height = 157;
  static const double thumbWidth = 88;

  const StudioProjectCard({
    super.key,
    required this.project,
    required this.width,
    this.emphasised = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.10),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: thumbWidth.w,
              child: _Thumb(url: project.cardImageUrl),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studioFormatLabel(l10n, project.format).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 8.sp,
                        height: 1.5,
                        letterSpacing: 1.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 15.sp,
                        height: 1.27,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_summary.isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Expanded(
                        child: Text(
                          _summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mediumGrey,
                            fontSize: 11.sp,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    SizedBox(height: 8.h),
                    _EpisodesButton(emphasised: emphasised, onTap: onTap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The one-line description is what the card is for; the short synopsis
  /// stands in when a project has no description yet.
  String get _summary => project.oneLineDescription.trim().isNotEmpty
      ? project.oneLineDescription
      : project.synopsisShort;
}

class _Thumb extends StatelessWidget {
  final String url;

  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(color: AppColors.mediumBackground);
    }

    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      thumb: true,
    );
  }
}

class _EpisodesButton extends StatelessWidget {
  final bool emphasised;
  final VoidCallback? onTap;

  const _EpisodesButton({required this.emphasised, this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = emphasised ? AppColors.white : AppColors.lightGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24.h,
        padding: EdgeInsets.symmetric(horizontal: 9.w),
        decoration: BoxDecoration(
          gradient: emphasised ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(3.r),
          border: emphasised
              ? null
              : Border.all(
                  color: AppColors.smoke.withValues(alpha: 0.12),
                  width: 0.6,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, size: 10.w, color: foreground),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context)!.studioViewEpisodes,
              style: TextStyle(
                color: foreground,
                fontSize: 11.sp,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
