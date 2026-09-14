import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_badges.dart';

/// The card used in the "Featured Films" rail: poster on top, title, credit
/// line, and a trailer button.
///
/// The trailer button is filled with the brand gradient on the first card and
/// outlined on the rest — the design uses it to draw the eye to the lead film,
/// so [emphasised] is set by position, not by anything on the film itself.
class FilmPosterCard extends StatelessWidget {
  final Film film;
  final bool emphasised;
  final VoidCallback? onTap;
  final VoidCallback? onWatchTrailer;

  static const double width = 158;
  static const double posterHeight = 158;
  static const double height = 246;

  const FilmPosterCard({
    super.key,
    required this.film,
    this.emphasised = false,
    this.onTap,
    this.onWatchTrailer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width.w,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: posterHeight.h,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Poster(url: film.cardImageUrl),
                  PositionedDirectional(
                    start: 7.w,
                    top: 7.h,
                    child: FilmBadges(
                      film: film,
                      style: FilmBadgeStyle.onImage,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      film.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 12.sp,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _creditLine(film),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 9.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (film.trailerUrl.isNotEmpty)
                      _TrailerButton(
                        emphasised: emphasised,
                        onTap: onWatchTrailer,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "2024 · Carolina Rodriguez", collapsing to just the year when there is no
  /// director credit rather than leaving a dangling separator.
  static String _creditLine(Film film) {
    final parts = [film.credits.year, film.credits.direction]
        .where((s) => s.trim().isNotEmpty);
    return parts.join(' · ');
  }
}

class _Poster extends StatelessWidget {
  final String url;

  const _Poster({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(color: AppColors.mediumBackground);
    }

    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      // A poster card is 158 logical pixels wide. The thumbnail is plenty.
      thumb: true,
    );
  }
}

class _TrailerButton extends StatelessWidget {
  final bool emphasised;
  final VoidCallback? onTap;

  const _TrailerButton({required this.emphasised, this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = emphasised ? AppColors.smoke : AppColors.lightGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24.h,
        padding: EdgeInsetsDirectional.symmetric(horizontal: 8.w),
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
            // Figma 2219:968 — the icon is 7px, not 9.
            Icon(Icons.play_arrow_rounded, size: 7.w, color: foreground),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context)!.filmsWatchTrailer,
              style: TextStyle(
                color: foreground,
                fontSize: 9.sp,
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
