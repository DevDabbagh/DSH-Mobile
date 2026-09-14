import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';
import 'package:dsh_mobile/layers/impact/data/repositories/impact_repository_impl.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/home/presentation/controllers/home_controller.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/colorize_on_scroll.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_header.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_hero_carousel.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_rails.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_sections.dart';

/// The Home screen.
///
/// This file was 1400 lines: the order of every section, every heading, and
/// six Unsplash URLs standing in for content that already existed in the
/// database — the same photograph repeated across four film cards, a title
/// reading "Mother Tongue" on every one of them.
///
/// It is now a dispatcher. The layout comes from `page_sections` where
/// `page = 'mobile_home'` (Mobile Settings → Mobile Landing in the
/// dashboard), and each section is a widget that reads its own live content.
/// Reordering the rails, renaming a heading or hiding a section is a drag in
/// the dashboard rather than a code change, a build and a store review.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// How long the screen will wait for the content providers before giving up
  /// on a tidy first paint and showing what it has.
  ///
  /// The point of waiting at all is to avoid the flicker: the layout arrives
  /// from one provider and the content from five more, so rendering the
  /// instant the layout lands makes every section come up empty, collapse
  /// itself, then reappear as its own query finishes.
  ///
  /// But waiting for ALL of them turns one slow query into a screen that
  /// never appears — which is a far worse failure than the flicker, and is
  /// exactly what happened. Six seconds buys the tidy paint on a normal
  /// connection and costs nothing on a bad one.
  static const _grace = Duration(seconds: 6);

  Timer? _graceTimer;
  bool _graceExpired = false;

  @override
  void initState() {
    super.initState();
    _graceTimer = Timer(_grace, () {
      if (mounted) setState(() => _graceExpired = true);
    });
  }

  @override
  void dispose() {
    _graceTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    // Everything, not just the layout. Someone pulling to refresh a stuck
    // Home is retrying the queries that stuck, and refreshing the one
    // provider that already succeeded helps nobody.
    ref.invalidate(heroSlidesProvider);
    ref.invalidate(filmsListProvider);
    ref.invalidate(studioListProvider);
    ref.invalidate(academyProgramsProvider);
    ref.invalidate(impactStatsProvider);
    ref.invalidate(impactStoriesProvider);
    await ref.read(homeControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(homeControllerProvider);

    // ONLY the carousel, not every rail.
    //
    // The first version waited for films, studio, academy and the impact
    // figures as well. Two things were wrong with that:
    //
    //   · Films, Studio and Academy are other tabs' data. Home shows a few
    //     of each, but holding the whole screen until all four have answered
    //     means the slowest query in the app decides when Home appears — and
    //     if one never answers, Home never appears at all.
    //   · It is not even what a feed should do. A rail that arrives a moment
    //     late slides into place below the fold; that is normal, and it is
    //     nothing like the flicker this was written to stop.
    //
    // The flicker was always about the top of the screen: the carousel is the
    // first thing you see and it occupies 380 pixels, so it collapsing and
    // reappearing moves everything under it. That is the one worth waiting
    // for. The rails keep their own placeholders and fill in behind it.
    //
    // An error counts as settled — one dead query must not hold the screen.
    final heroLoading = ref.watch(heroSlidesProvider).isLoading;

    // The layout is the only hard requirement: without it there is nothing to
    // lay out. The carousel merely gets the grace period.
    final waiting = sections.isLoading || (heroLoading && !_graceExpired);

    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: SafeArea(
        child: sections.hasError
            ? ErrorRetryWidget(
                message: sections.error is Failure
                    ? (sections.error as Failure).message
                    : sections.error.toString(),
                onRetry: _refresh,
              )
            : RefreshIndicator(
                color: AppColors.mainBlue,
                backgroundColor: AppColors.cardSurface,
                onRefresh: _refresh,
                // The indicator wraps BOTH states now.
                //
                // It used to wrap only the loaded one, so the slow-connection
                // hint said "pull down to refresh" over a shimmer that was
                // not scrollable and had no indicator attached — advice the
                // screen made impossible to follow.
                child: waiting
                    ? const _HomeLoading()
                    : _Content(sections: sections.requireValue),
              ),
      ),
    );
  }
}

/// The shimmer, plus a way out of it.
///
/// A shimmer says "this is coming". On a bad connection that is a promise the
/// app cannot keep, and the reader is left watching a grey pulse with nothing
/// to press. After [_hintAfter] the screen admits it is stuck and offers the
/// only thing that helps.
class _HomeLoading extends StatefulWidget {
  const _HomeLoading();

  @override
  State<_HomeLoading> createState() => _HomeLoadingState();
}

class _HomeLoadingState extends State<_HomeLoading> {
  /// Long enough that a slow-but-working connection is never accused of being
  /// broken; short enough that nobody sits through a minute of nothing.
  static const _hintAfter = Duration(seconds: 8);

  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hintAfter, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: HomeShimmer()),
        if (_slow)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 110.h,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 32.w),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.smoke.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.mediumGrey,
                      size: 16.w,
                    ),
                    SizedBox(width: 10.w),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.homeSlowConnection,
                        style: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Content extends StatefulWidget {
  final List<HomeSection> sections;

  const _Content({required this.sections});

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  /// Owned here and published through `HomeScrollScope` so every still on the
  /// screen can colour itself as it rises, without each rail having to be
  /// handed a controller.
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScrollScope(
      controller: _controller,
      child: _scrollView(),
    );
  }

  Widget _scrollView() {
    return SingleChildScrollView(
      controller: _controller,
      // Always scrollable, so pull-to-refresh works even when the layout is
      // short enough to fit the screen — otherwise Home cannot be refreshed
      // on the one occasion it most needs to be: when it has come back
      // nearly empty.
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          SizedBox(height: 16.h),
          for (final section in widget.sections) _SectionSlot(section: section),
          // Clear of the floating tab bar.
          SizedBox(height: 100.h),
        ],
      ),
    );
  }
}

/// Picks the widget for a section's kind.
///
/// The gap beneath each section is applied by the section itself, through
/// `homeSection()` — a section that renders nothing must take up nothing,
/// and only the section knows whether it has content.
class _SectionSlot extends StatelessWidget {
  final HomeSection section;

  const _SectionSlot({required this.section});

  @override
  Widget build(BuildContext context) {
    final child = switch (section.kind) {
      HomeSectionKind.heroCarousel => HomeHeroCarousel(section: section),
      HomeSectionKind.search => HomeSearchBar(section: section),
      HomeSectionKind.quickActions => HomeQuickActions(section: section),
      HomeSectionKind.filmsRail => HomeFilmsRail(section: section),
      HomeSectionKind.studioRail => HomeStudioRail(section: section),
      HomeSectionKind.academyRail => HomeAcademyRail(section: section),
      HomeSectionKind.inFocus => HomeInFocus(section: section),
      HomeSectionKind.impact => HomeImpact(section: section),
      HomeSectionKind.cta => HomeCta(section: section),
      // The model drops unknown kinds before they reach here. This arm keeps
      // the switch exhaustive rather than describing a reachable state.
      HomeSectionKind.unknown => const SizedBox.shrink(),
    };

    // No padding here. Every section already applies its own gap — through
    // `homeSection()`, or its own Padding in the carousel's case — and this
    // wrapper was adding a second 32 on top of it. The result was 64 between
    // every pair on the screen, which is why the search field looked adrift
    // from the carousel above it. The doc comment above this class said the
    // gap belonged to the section; the code then added one anyway.
    return child;
  }
}
