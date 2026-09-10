import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

/// The uppercase form/stage labels a film card carries ("DOCUMENTARY",
/// "FESTIVALS").
///
/// Two looks for the same information: filled dark chips when they sit on top
/// of a poster, outlined chips when they sit on the card's own background.
enum FilmBadgeStyle { onImage, onSurface }

class FilmBadges extends StatelessWidget {
  final Film film;
  final FilmBadgeStyle style;

  const FilmBadges({
    super.key,
    required this.film,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            SizedBox(width: style == FilmBadgeStyle.onImage ? 4.w : 5.w),
          _Badge(
            label: labels[i],
            style: style,
            // The design gives the second chip slightly less presence than
            // the first — form matters more than stage.
            secondary: i > 0,
          ),
        ],
      ],
    );
  }

  /// Form always shows. Stage only shows once a film has actually moved past
  /// development, since "DEVELOPMENT" on every card carries no information.
  List<String> _labels(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final out = <String>[formLabel(l10n, film.credits)];

    if (film.stage != FilmStage.development) {
      out.add(stageLabel(l10n, film.stage));
    }

    return out;
  }

  /// Also used by the detail screens, which show the same vocabulary in a
  /// credits table rather than as chips.
  static String formLabel(AppLocalizations l10n, FilmCredits credits) {
    // A short or a series is described by its format; a feature by whether it
    // is documentary or fiction. That is how the design labels them.
    switch (credits.format) {
      case FilmFormat.short:
        return l10n.filmFormatShort;
      case FilmFormat.series:
        return l10n.filmFormatSeries;
      case FilmFormat.feature:
        return credits.form == FilmForm.fiction
            ? l10n.filmFormFiction
            : l10n.filmFormDocumentary;
    }
  }

  static String stageLabel(AppLocalizations l10n, FilmStage stage) {
    switch (stage) {
      case FilmStage.development:
        return l10n.filmStageDevelopment;
      case FilmStage.production:
        return l10n.filmStageProduction;
      case FilmStage.postProduction:
        return l10n.filmStagePostProduction;
      case FilmStage.festivals:
        return l10n.filmStageFestivals;
      case FilmStage.distribution:
        return l10n.filmStageDistribution;
      case FilmStage.impact:
        return l10n.filmStageImpact;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final FilmBadgeStyle style;
  final bool secondary;

  const _Badge({
    required this.label,
    required this.style,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final onImage = style == FilmBadgeStyle.onImage;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: onImage ? 2.h : 1.h,
      ),
      decoration: BoxDecoration(
        color: onImage
            ? AppColors.black.withValues(alpha: secondary ? 0.55 : 0.62)
            : null,
        borderRadius: BorderRadius.circular(2.r),
        border: onImage
            ? null
            : Border.all(
                color:
                    AppColors.smoke.withValues(alpha: secondary ? 0.08 : 0.10),
                width: 0.6,
              ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: onImage ? AppColors.smoke : AppColors.lightGrey,
          fontSize: onImage ? 7.sp : 8.sp,
          height: 1.5,
          fontWeight: FontWeight.bold,
          letterSpacing: onImage ? 0.7 : 0.96,
        ),
      ),
    );
  }
}
