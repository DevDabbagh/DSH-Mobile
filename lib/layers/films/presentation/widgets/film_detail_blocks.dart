import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

/// Synopsis copy that starts clamped and expands in place.
///
/// Expands rather than opening a sheet: the synopsis is the reason someone
/// opened the page, and pushing it behind another tap costs more than the
/// scroll it saves. The toggle is hidden entirely when the text is short
/// enough to fit, so there is no "Read more" that does nothing.
class ExpandableText extends StatefulWidget {
  final String text;
  final int collapsedLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.collapsedLines = 4,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = TextStyle(
      color: AppColors.lightGrey,
      fontSize: 12.sp,
      height: 1.65,
      fontWeight: FontWeight.w500,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Lay the paragraph out once to find out whether it actually
        // overflows; only then is a toggle worth showing.
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : widget.collapsedLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows) ...[
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? l10n.filmReadLess : l10n.filmReadMore,
                  // Figma 2170:1282 — underlined white, not a purple link.
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The editorial-context card — why DSH is backing this film.
///
/// Tinted rather than plain so it reads as the house's own voice, distinct
/// from the synopsis, which is the film's.
class EditorialContextCard extends StatelessWidget {
  final String text;

  const EditorialContextCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.mainPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.mainPurple.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 11.w,
                color: AppColors.mainPurple,
              ),
              SizedBox(width: 6.w),
              Text(
                AppLocalizations.of(context)!
                    .filmSectionEditorial
                    .toUpperCase(),
                // Figma 2170:1292 — 9/13.5, 1.08 tracking.
                style: TextStyle(
                  color: AppColors.mainPurple,
                  fontSize: 9.sp,
                  height: 1.5,
                  letterSpacing: 1.08,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            text,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 12.sp,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Festivals and awards, two to a row.
class FestivalGrid extends StatelessWidget {
  final List<FilmFestival> festivals;

  const FestivalGrid({super.key, required this.festivals});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        for (final f in festivals)
          SizedBox(
            // Two per row, accounting for the gap between them.
            width: (MediaQuery.sizeOf(context).width - 40.w - 10.w) / 2,
            child: _FestivalCard(festival: f),
          ),
      ],
    );
  }
}

class _FestivalCard extends StatelessWidget {
  final FilmFestival festival;

  const _FestivalCard({required this.festival});

  @override
  Widget build(BuildContext context) {
    // An award outranks a plain selection when both are recorded — it is the
    // stronger claim, and the card only has room for one line.
    final accolade = festival.award ?? festival.selection;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 16.w,
            color: AppColors.mainPurple,
          ),
          SizedBox(height: 8.h),
          Text(
            festival.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            // Figma 2170:1359 — semibold, plain white.
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (festival.year.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              festival.year,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 9.sp,
                height: 1.5,
              ),
            ),
          ],
          if (accolade != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.mainPurple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: Text(
                accolade.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.purpleLight2,
                  fontSize: 7.sp,
                  height: 1.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A screening: date block on the leading edge, venue in the middle, RSVP on
/// the trailing edge.
class ScreeningRow extends StatelessWidget {
  final FilmScreening screening;
  final VoidCallback? onRsvp;

  const ScreeningRow({super.key, required this.screening, this.onRsvp});

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(screening.date);

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          _DateBlock(date: parsed, raw: screening.date),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screening.event,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 12.sp,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (screening.location.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    screening.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: 10.sp,
                      height: 1.5,
                    ),
                  ),
                ],
                if (screening.type.isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Text(
                    screening.type.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: AppColors.purpleLight2,
                      fontSize: 7.sp,
                      height: 1.5,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRsvp != null)
            GestureDetector(
              onTap: onRsvp,
              child: Text(
                AppLocalizations.of(context)!.filmRsvp,
                // Figma 2170:1418 — dim white, not a purple call to action.
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.25),
                  fontSize: 11.sp,
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

class _DateBlock extends StatelessWidget {
  final DateTime? date;
  final String raw;

  const _DateBlock({required this.date, required this.raw});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final d = date;

    return Container(
      width: 40.w,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.mediumBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Column(
        children: d == null
            // A date the database stores as free text ("Autumn 2026") can't be
            // split into month and day, so show it as written rather than
            // dropping it.
            ? [
                Text(
                  raw.isEmpty ? '—' : raw,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 9.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Text(
                  _months[d.month - 1].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.mainPurple,
                    fontSize: 8.sp,
                    height: 1.4,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${d.day}',
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 15.sp,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
      ),
    );
  }
}

/// A press pull-quote with its source underneath.
class PressQuoteBlock extends StatelessWidget {
  final FilmPressQuote quote;

  const PressQuoteBlock({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“${quote.quote}”',
          style: TextStyle(
            color: AppColors.smoke,
            fontSize: 12.sp,
            height: 1.6,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (quote.source.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            '— ${quote.source}',
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 10.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// The support call-to-action that closes the page.
class SupportCard extends StatelessWidget {
  final VoidCallback? onTap;

  const SupportCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 18.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 0.6,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.filmSupportTitle,
            textAlign: TextAlign.center,
            // Figma 2170:1519 — 15/22.5 semibold, plain white.
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l10n.filmSupportBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 11.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.filmSupportCta,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11.sp,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_forward,
                    size: 12.w,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
