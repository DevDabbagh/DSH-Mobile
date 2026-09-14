import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/home/domain/entities/hero_slide.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';
import 'package:dsh_mobile/layers/home/presentation/controllers/home_controller.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/hero_slide_video.dart';

/// The featured carousel.
///
/// Shows the website's Header Slider — the same cards, in the same order,
/// from the row Landing Settings writes to `landing_page_config`. The app
/// used to build its own carousel from the newest published films, so an
/// editor who curated seven cards for the site found the app ignoring every
/// one of them. One slider, edited once.
///
/// (Before that it repeated a single Unsplash photograph five times, with
/// the title "What We Carried" on every slide.)
class HomeHeroCarousel extends ConsumerStatefulWidget {
  final HomeSection section;

  const HomeHeroCarousel({super.key, required this.section});

  @override
  ConsumerState<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends ConsumerState<HomeHeroCarousel> {
  /// How long the slide takes to move, and on what curve.
  ///
  /// Both taken from the website's Hero — `duration-[1100ms]` with
  /// `cubic-bezier(0.16, 1, 0.3, 1)`. The app was on 800ms `easeInOut`, which
  /// is a noticeably brisker, more mechanical movement for the same carousel.
  /// It is one slider; it should move one way.
  static const _slideDuration = Duration(milliseconds: 1100);
  static const _slideCurve = Cubic(0.16, 1, 0.3, 1);

  /// The first slide advances sooner than the rest.
  ///
  /// Ten seconds is right once someone is reading, but it is a long time to
  /// look at a carousel with no evidence that it is a carousel. Moving once
  /// early says "there is more here" and then gets out of the way.
  static const _firstAdvance = Duration(seconds: 2);

  // initialPage well inside the range so the infinite scroll has somewhere to
  // go in both directions from the first frame.
  final PageController _controller =
      PageController(viewportFraction: 0.60, initialPage: 3000);

  /// The one-shot that fires the early first move.
  Timer? _leadIn;

  /// The steady interval that takes over afterwards.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  void _startAutoplay() {
    _leadIn?.cancel();
    _timer?.cancel();

    _leadIn = Timer(_firstAdvance, () {
      _advance();
      // Only now does the steady rhythm begin, so the gap between the first
      // and second slide is the full interval rather than 8 seconds.
      _timer = Timer.periodic(
        Duration(seconds: widget.section.autoplaySeconds),
        (_) => _advance(),
      );
    });
  }

  void _advance() {
    // hasClients guards the case where the carousel scrolled off screen and
    // the controller detached before the timer fired.
    if (!_controller.hasClients) return;
    _controller.nextPage(duration: _slideDuration, curve: _slideCurve);
  }

  @override
  void didUpdateWidget(HomeHeroCarousel old) {
    super.didUpdateWidget(old);
    // The dashboard can change the interval; without this the old timer
    // survives until the screen is rebuilt from scratch.
    if (old.section.autoplaySeconds != widget.section.autoplaySeconds) {
      _startAutoplay();
    }
  }

  @override
  void dispose() {
    _leadIn?.cancel();
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(heroSlidesProvider).valueOrNull ?? const [];
    final items = slides.take(widget.section.limit).toList();

    // The slider is switched off in Landing Settings, has no cards, or has
    // not been saved yet. An empty carousel of grey rectangles is worse than
    // no carousel.
    if (items.isEmpty) return const SizedBox.shrink();

    // 26, between the tight 14 and the standard 32.
    //
    // 14 put the search field almost against the bottom of the carousel, and
    // the carousel's own slides are scaled and shadowed — so the field looked
    // like it was resting on the edge of the centre card rather than sitting
    // under the whole section.
    return Padding(
      padding: EdgeInsets.only(bottom: 26.h),
      child: SizedBox(
        height: 380.h,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemBuilder: (context, index) {
                final slide = items[index % items.length];

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_controller.position.haveDimensions) {
                      value = _controller.page! - index;
                      value = value.clamp(-1.0, 1.0);
                    }

                    final scale = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                    final isCentre = value.abs() < 0.5;
                    final captionOpacity =
                        (1 - (value.abs() * 2)).clamp(0.0, 1.0);

                    // The poster is always the base layer — for a still that is the
                    // image itself, for a video the slot's imageSrc. A video
                    // that fails to load leaves the poster showing rather
                    // than a black rectangle. Same order as the site.
                    Widget image = AppNetworkImage(
                      url: slide.posterUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );

                    // Only the centre slide keeps its colour — the flanking
                    // ones desaturate, which is the whole point of the effect.
                    if (!isCentre) {
                      image = ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0.2126, 0.7152, 0.0722, 0, 0, //
                          0, 0, 0, 1, 0, //
                        ]),
                        child: image,
                      );
                    }

                    return Center(
                      child: SizedBox(
                        height: Curves.easeOut.transform(scale) * 380.h,
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: slide.hasLink
                              ? () => context.push(slide.ctaLink)
                              : null,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: image,
                                ),
                                // The video plays only on the centre slide,
                                // exactly as the site does it
                                // (`mediaType === "video" && isActive`).
                                // Mounting one per slide would leave seven
                                // decoders running behind a screen showing
                                // one of them.
                                if (slide.isVideo && isCentre)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.r),
                                      child: HeroSlideVideo(
                                        key: ValueKey(slide.id),
                                        url: slide.mediaUrl,
                                      ),
                                    ),
                                  ),
                                // The gradient belongs to the image, not to the
                                // caption. It used to sit inside the Opacity
                                // that fades the caption out, so on the side
                                // cards it faded too and they ended in a hard
                                // edge against the background.
                                //
                                // Positioned.fill rather than a plain child:
                                // the Stack sizes itself from the ClipRRect
                                // above, and fill copies that size exactly. A
                                // bare DecoratedBox has no intrinsic size and
                                // collapses.
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(6.r),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.center,
                                          colors: [
                                            AppColors.brandBlack
                                                .withValues(alpha: 0.95),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                PositionedDirectional(
                                  start: 20.w,
                                  bottom: 24.h,
                                  end: 20.w,
                                  child: Opacity(
                                    opacity: captionOpacity,
                                    child: _Caption(slide: slide),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const _EdgeFade(start: true),
            const _EdgeFade(start: false),

            // AFTER the fades, so they sit on top of them.
            //
            // The fades are 80 wide and nearly opaque at the edge — an arrow
            // drawn before them would be behind the darkest part of the
            // gradient, which is exactly where it is placed. Painting order in
            // a Stack is child order, so these have to be last.
            _NavArrow(
              start: true,
              onTap: () => _step(-1, items.length),
            ),
            _NavArrow(
              start: false,
              onTap: () => _step(1, items.length),
            ),
          ],
        ),
      ),
    );
  }

  /// One slide forward or back.
  ///
  /// Restarts the autoplay timer: someone who has just pressed an arrow is
  /// reading that slide, and having it slide away a moment later because the
  /// old interval happened to be nearly up is the worst possible timing.
  void _step(int direction, int count) {
    // `page` is null until the PageView has been laid out, and an arrow can
    // be pressed on the first frame.
    if (count == 0 || !_controller.hasClients || _controller.page == null) {
      return;
    }

    _controller.animateToPage(
      _controller.page!.round() + direction,
      duration: _slideDuration,
      curve: _slideCurve,
    );
    _startAutoplay();
  }
}

class _Caption extends StatelessWidget {
  final HeroSlide slide;

  const _Caption({required this.slide});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          // The editor's own label — "Documentary", "Youtube Series" — or the
          // app's stock eyebrow when the card carries none.
          slide.cardType.isNotEmpty ? slide.cardType : l10n.homeFocusToday,
          style: TextStyle(
            color: AppColors.mainPurple,
            fontSize: 10.sp,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          // Written with line breaks in the editor, which the card design
          // relies on, so they are passed through rather than collapsed.
          slide.cardTitle,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.homeViewMore,
                    style: TextStyle(color: AppColors.white, fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.add, color: AppColors.mainPurple, size: 14.w),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A step back or forward, sitting over the slide beside the centre one.
///
/// Placed on the side card rather than on the centre one: the centre slide is
/// the thing being read, and an arrow over it covers the picture and competes
/// with "View more". Over the neighbour it points at what it will bring in.
///
/// Backdrop-blurred and translucent rather than solid, because it lands on a
/// photograph in one position and on the near-black edge fade in another, and
/// a flat colour can only be legible on one of the two.
class _NavArrow extends StatelessWidget {
  final bool start;
  final VoidCallback onTap;

  const _NavArrow({required this.start, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: start ? 14.w : null,
      end: start ? null : 14.w,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                width: 34.w,
                height: 34.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.45),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                // The glyph follows the reading direction, not the side.
                //
                // `PositionedDirectional` already puts `start` on the right in
                // Arabic — but a Material chevron does not flip with it, so
                // the button on the right would have carried a left-pointing
                // arrow and meant the opposite of what it did. Resolved
                // against the ambient direction instead.
                child: Builder(
                  builder: (context) {
                    final ltr = Directionality.of(context) == TextDirection.ltr;
                    final pointsLeft = start == ltr;
                    return Icon(
                      pointsLeft
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.white,
                      size: 22.w,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The black fade over each edge, so slides arrive and leave rather than
/// being cut off by the screen.
class _EdgeFade extends StatelessWidget {
  final bool start;

  const _EdgeFade({required this.start});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: start ? 0 : null,
      end: start ? null : 0,
      top: 0,
      bottom: 0,
      width: 80.w,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: start
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              end: start
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              colors: [
                AppColors.brandBlack.withValues(alpha: 0.95),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
