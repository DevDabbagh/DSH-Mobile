import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_badges.dart';

/// The wide row used in the "Library" list: a narrow still on the leading
/// edge, then badges, title, credit line and a two-line logline.
class FilmListCard extends StatelessWidget {
  final Film film;
  final VoidCallback? onTap;

  static const double height = 122;
  static const double thumbWidth = 72;

  const FilmListCard({super.key, required this.film, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                width: thumbWidth.w, child: _Thumb(url: film.cardImageUrl)),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                    end: 14.w, top: 12.h, bottom: 12.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilmBadges(film: film, style: FilmBadgeStyle.onSurface),
                    SizedBox(height: 5.h),
                    Text(
                      film.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 14.sp,
                        height: 1.3,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _creditLine(film),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 11.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_summary(film).isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Text(
                        _summary(film),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 11.sp,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The list uses "Dir." before the director; the rail card does not.
  static String _creditLine(Film film) {
    final year = film.credits.year.trim();
    final director = film.credits.direction.trim();

    if (year.isEmpty) return director.isEmpty ? '' : 'Dir. $director';
    if (director.isEmpty) return year;
    return '$year · Dir. $director';
  }

  /// The logline is what this row is for; the short synopsis stands in when a
  /// film has no logline written yet.
  static String _summary(Film film) =>
      film.logline.trim().isNotEmpty ? film.logline : film.synopsisShort;
}

class _Thumb extends StatelessWidget {
  final String url;

  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isEmpty)
          const ColoredBox(color: AppColors.mediumBackground)
        else
          AppNetworkImage(
            url: url,
            fit: BoxFit.cover,
            // A still at list-row size.
            thumb: true,
          ),
        // Feathers the still into the card body so there is no hard vertical
        // seam between image and text.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                AppColors.cardSurface.withValues(alpha: 0),
                AppColors.cardSurface.withValues(alpha: 0.5),
              ],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
