import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

/// The chrome around one onboarding slide: darkened background imagery, the
/// top/bottom scrims that keep text legible, and slots for the logo and copy.
///
/// Takes a [background] widget rather than a URL, so the caller decides how
/// the imagery behaves — one image, a cross-fade, or nothing at all.
class OnboardingSlide extends StatelessWidget {
  final Widget background;
  final Widget? topContent;
  final Widget bottomContent;

  const OnboardingSlide({
    super.key,
    required this.background,
    this.topContent,
    required this.bottomContent,
  });

  /// Luminance-weighted desaturation — the same coefficients the Home hero
  /// uses, so a photo looks identical wherever it appears. A plain average of
  /// the channels would wash out reds and darken blues.
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background imagery, desaturated and then knocked back.
        //
        // Two filters, in this order. The greyscale pass is the design's:
        // every onboarding photograph is black and white, which is what keeps
        // the only colour on screen — the gradient words and the logo — doing
        // the work. Darkening alone left a full-colour photo competing with
        // the copy.
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppColors.background.withValues(alpha: 0.5),
            BlendMode.darken,
          ),
          child: ColorFiltered(
            colorFilter: _greyscale,
            child: background,
          ),
        ),
        // Top and Bottom Gradient (Shadow) to ensure text/logo readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.8), // Top shadow
                AppColors.background.withValues(alpha: 0.0), // Clear middle
                AppColors.background.withValues(alpha: 0.0), // Clear middle
                AppColors.background
                    .withValues(alpha: 0.8), // Bottom shadow starts
                AppColors.background, // Solid background at bottom
              ],
              stops: const [0.0, 0.25, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        // Safe Area Content
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topContent != null)
                Padding(
                  // Figma 2046:10887 — the logo block sits 80 from the top of
                  // the frame. SafeArea has already taken the status bar, so
                  // this is the remainder rather than the full 80.
                  padding: EdgeInsetsDirectional.only(top: 40.h),
                  child: topContent!,
                ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: bottomContent,
              ),
              SizedBox(height: 100.h), // Space for navigation row
            ],
          ),
        ),
      ],
    );
  }
}
