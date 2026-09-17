/// The small repeated parts of the Academy tab — Figma 2266:806.
///
/// The type chip, the price word and the filter pill each appear in three or
/// four places at slightly different sizes, and the frame is specific about
/// which size goes where. Defining them once with a size parameter is what
/// stops the featured card and the list card drifting into two chips that are
/// nearly the same.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';

/// "Courses", "Workshops", … — the same map as `TYPE_LABELS` in the website's
/// `AcademyListing.tsx`, so a chip reads identically on both surfaces.
///
/// Plural because these double as the filter tabs, where they name a group.
String academyTypeLabel(AcademyType type) => switch (type) {
      AcademyType.course => 'Courses',
      AcademyType.workshop => 'Workshops',
      AcademyType.toolkit => 'Toolkits',
      // The site maps `resource` to "Toolkits" as well — one concept the
      // database happens to spell two ways.
      AcademyType.resource => 'Toolkits',
      AcademyType.mentorship => 'Mentorships',
    };

/// The singular, for a chip that labels one programme rather than a group:
/// the frame reads "MENTORSHIP", not "MENTORSHIPS".
String academyTypeChip(AcademyType type) => switch (type) {
      AcademyType.course => 'Course',
      AcademyType.workshop => 'Workshop',
      AcademyType.toolkit => 'Toolkit',
      AcademyType.resource => 'Toolkit',
      AcademyType.mentorship => 'Mentorship',
    };

/// How it is delivered — the grey word beside the chip (2266:1109).
String academyFormatLabel(AcademyFormat format) => switch (format) {
      AcademyFormat.online => 'Online',
      AcademyFormat.inPerson => 'In person',
      AcademyFormat.hybrid => 'Hybrid',
      AcademyFormat.selfPaced => 'Self-paced',
      AcademyFormat.downloadable => 'Downloadable',
    };

/// What it costs, in the frame's words.
///
/// Follows `ProgramMeta` on the website: free first, then a scholarship note
/// if there is one, then the price. The order matters — a paid programme with
/// scholarship places should say so rather than lead with a number that is not
/// the whole story.
///
/// A paid programme with no price falls through to "Paid": [AcademyProgram]
/// treats that row as free for the purpose of `isPaid`, but the label here is
/// about what the editor said, and silently printing "Free" over a row somebody
/// meant to charge for is the more expensive mistake.
({String text, Color color}) academyPriceLabel(AcademyProgram p) {
  if (p.isFree) return (text: 'Free', color: AppColors.academyFree);

  if (p.scholarshipNote.trim().isNotEmpty) {
    return (text: 'Scholarship available', color: AppColors.mainBlue);
  }

  if (p.price != null && p.price! > 0) {
    final amount = p.price!;
    // No decimals on a whole number: the frame reads "€60", not "€60.00".
    final printed = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toStringAsFixed(2);
    return (text: '${_symbol(p.currency)}$printed', color: AppColors.smoke);
  }

  return (text: 'Paid', color: AppColors.lightGrey);
}

String _symbol(String currency) => switch (currency.toUpperCase()) {
      'EUR' => '€',
      'USD' => r'$',
      'GBP' => '£',
      // An unknown code is printed as itself with a space — better an ugly
      // "BRL 60" than a number with no unit on it.
      _ => currency.isEmpty ? '' : '$currency ',
    };

/// The teal category chip.
///
/// Two sizes, both from the frame: [small] is the one on a list card
/// (2266:1105 — 9px, 1.08 tracking, outline only) and the default is the one
/// over the featured still (2266:1018 — 8px, 0.8 tracking, filled).
class AcademyTypeChip extends StatelessWidget {
  final String label;
  final bool small;

  const AcademyTypeChip({super.key, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5.w : 6.w,
        vertical: small ? 1.h : 2.h,
      ),
      decoration: BoxDecoration(
        // The outline-only variant on a list card is deliberate: those chips
        // sit on a card that already has a background, and a second filled
        // rectangle there reads as a button.
        color: small ? null : AppColors.mainBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2.r),
        border: Border.all(
          color: AppColors.mainBlue.withValues(alpha: small ? 0.20 : 0.30),
          width: 0.6,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.mainBlue,
          fontSize: small ? 9.sp : 8.sp,
          height: 1.5,
          letterSpacing: small ? 1.08 : 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// One chip in either filter strip.
///
/// [dense] is the price row (2266:1080 — 26 tall, 10px) as against the type
/// row (2266:1055 — 28 tall, 11px). Selected takes the Academy teal; the price
/// row's selected state is a neutral white wash instead, because a teal "Free"
/// beside a lime "Free" was two accent colours arguing over one word.
class AcademyFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  /// Overrides the unselected text colour — the Free chip carries the lime.
  final Color? idleColor;

  const AcademyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
    this.idleColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color borderColor;
    final Color textColor;

    if (selected && dense) {
      background = AppColors.smoke.withValues(alpha: 0.09);
      borderColor = AppColors.smoke.withValues(alpha: 0.18);
      textColor = AppColors.smoke;
    } else if (selected) {
      background = AppColors.mainBlue.withValues(alpha: 0.12);
      borderColor = AppColors.mainBlue.withValues(alpha: 0.35);
      textColor = AppColors.smoke;
    } else {
      background = Colors.transparent;
      borderColor = AppColors.smoke.withValues(alpha: dense ? 0.05 : 0.06);
      textColor = idleColor ?? AppColors.lightGrey;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: dense ? 26.h : 28.h,
        padding: EdgeInsets.symmetric(horizontal: dense ? 10.w : 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(color: borderColor, width: 0.6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: dense ? 10.sp : 11.sp,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// The teal→pink gradient bar, used as the button fill and as the 2px rule
/// under a list card's thumbnail (2266:1102).
class AcademyGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AcademyGradientButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3.r),
        child: Ink(
          height: 40.h,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.smoke,
                fontSize: 13.sp,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
