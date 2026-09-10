import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/onboarding/domain/entities/onboarding_slide.dart'
    as domain;
import 'package:dsh_mobile/layers/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:dsh_mobile/layers/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/layers/onboarding/presentation/widgets/slide_images.dart';

/// First-launch onboarding.
///
/// Every slide — imagery, copy, order, whether the logo shows — comes from
/// Dashboard → Mobile Settings. Nothing here is hardcoded, so changing the
/// wording no longer needs an app release.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int total) {
    if (_currentIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(onboardingControllerProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingControllerProvider, (previous, next) {
      if (next is AsyncData) {
        // Straight to Home, signed in or not — the app is browsable without
        // an account, and an account is only asked for at the actions that
        // need one. This used to land guests on Login.
        context.go('/home');
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    final slidesState = ref.watch(onboardingSlidesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: slidesState.when(
        loading: () => const _OnboardingShimmer(),
        // The controller already turns a failed fetch into an empty list, so
        // this branch only fires on an explicit retry that failed again.
        error: (_, __) => _EmptyOnboarding(onContinue: _finish),
        data: (slides) => slides.isEmpty
            ? _EmptyOnboarding(onContinue: _finish)
            : _buildSlides(context, slides),
      ),
    );
  }

  Widget _buildSlides(
      BuildContext context, List<domain.OnboardingSlide> slides) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isLast = _currentIndex >= slides.length - 1;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: slides.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final slide = slides[index];

            return OnboardingSlide(
              background: SlideImages(images: slide.images),
              topContent: slide.showLogo
                  ? SvgPicture.asset(
                      // Figma 2046:10888 — 150×73, centred.
                      'assets/icons/ic_logo.svg',
                      width: 150.w,
                      height: 73.h,
                      fit: BoxFit.contain,
                    )
                  : null,
              bottomContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedHeadline(
                    segments: slide.titleSegments,
                    style: textTheme.displayLarge,
                  ),
                  if (slide.description.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      slide.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        // Skip — available on every slide except the last, where "Get started"
        // already does the same thing.
        if (!isLast)
          PositionedDirectional(
            top: 50.h,
            end: AppDimensions.pagePadding.w,
            child: SafeArea(
              child: GestureDetector(
                onTap: _finish,
                child: Text(
                  l10n.onboardingSkip,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

        // Dots + next
        PositionedDirectional(
          bottom: 40.h,
          start: AppDimensions.pagePadding.w,
          end: AppDimensions.pagePadding.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: SizedBox()),
              // Figma 2046:10891 — the active dot is a slightly larger
              // circle, not a pill. ScaleEffect grows it in place;
              // ExpandingDotsEffect stretched it sideways.
              SmoothPageIndicator(
                controller: _pageController,
                count: slides.length,
                effect: ScaleEffect(
                  activeDotColor: AppColors.white,
                  dotColor: const Color(0xFF666666),
                  dotHeight: 6.r,
                  dotWidth: 6.r,
                  scale: 8 / 6,
                  spacing: 8.w,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: GestureDetector(
                    onTap: () => _onNext(slides.length),
                    child: Text(
                      isLast ? l10n.onboardingGetStarted : l10n.onboardingNext,
                      // Figma 2046:10896 — medium 14/21, not bold.
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown while the slides load. Mirrors the real layout — a full-bleed image
/// area with two text bars at the bottom — so the switch doesn't jump.
class _OnboardingShimmer extends StatelessWidget {
  const _OnboardingShimmer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppDimensions.pagePadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            _bar(width: double.infinity, height: 28.h),
            SizedBox(height: 10.h),
            _bar(width: 260.w, height: 28.h),
            SizedBox(height: 20.h),
            _bar(width: 200.w, height: 14.h),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6.r),
        ),
      );
}

/// No slides configured, or a retry that still failed.
///
/// Deliberately quiet: onboarding is optional, so this offers a way forward
/// instead of an error the reader can do nothing about.
class _EmptyOnboarding extends StatelessWidget {
  final VoidCallback onContinue;

  const _EmptyOnboarding({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppDimensions.pagePadding.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/ic_logo.svg',
                width: 160.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 32.h),
              GestureDetector(
                onTap: onContinue,
                child: Text(
                  l10n.onboardingGetStarted,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
