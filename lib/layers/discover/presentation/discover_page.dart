import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/impact/data/repositories/impact_repository_impl.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_stat.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_story.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';
import 'package:dsh_mobile/layers/pages/presentation/controllers/page_sections_controller.dart';
import 'package:dsh_mobile/layers/pages/presentation/widgets/page_section_blocks.dart';

/// Impact — the app's `/discover` route.
///
/// WHAT THIS REPLACES
///
/// Five hundred lines with every word typed into the file, four Unsplash
/// photographs of strangers standing in for DSH's work, three invented
/// figures, and no way back to Home. An invented impact figure is the single
/// worst thing this app could print, and this screen was printing three.
///
/// WHERE EVERY PART NOW COMES FROM
///
///   · the prose      — `page_sections` where page = 'impact' (migration 040),
///                      written in the dashboard's Pages editor, in all three
///                      languages, reorderable and hideable like About and
///                      Support.
///   · the figures    — `impact_stats`, the same rows Home's rail reads and
///                      /admin/impact edits. One figure, one home.
///   · the stories    — `impact_stories`, published rows only.
///   · the imagery    — the header pools the dashboard already fills for the
///                      Films, Studio and Academy tabs, so this screen is
///                      part of the same wall of pictures rather than a
///                      separate set nobody remembers to update.
///
/// THE ONE SECTION THAT IS NOT COPY
///
/// `kind = 'impact'` is a marker: it carries a heading and a count and no
/// content, because the numbers underneath it belong to `impact_stats`.
/// [_FiguresAndStories] renders it, and renders the stories with it — the two
/// answer the same question in different units, and an editor moving one
/// without the other has never once been what was wanted.
class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(pageSectionsListProvider('impact'));

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: sections.when(
        loading: () => const _ImpactSkeleton(),
        error: (_, __) => SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load this page.',
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 14.sp,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(pageSectionsListProvider('impact').notifier)
                          .refresh(),
                      child: Text(
                        'Try again',
                        style: TextStyle(
                          color: AppColors.mainPurple,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _BackButton(),
            ],
          ),
        ),
        data: (list) => Stack(
          children: [
            RefreshIndicator(
              color: AppColors.mainPurple,
              backgroundColor: AppColors.cardSurface,
              onRefresh: () async {
                // All three sources, not just the copy — someone pulling to
                // refresh an Impact screen is almost always checking a figure
                // they just changed in the dashboard.
                ref.invalidate(impactStatsProvider);
                ref.invalidate(impactStoriesProvider);
                await ref
                    .read(pageSectionsListProvider('impact').notifier)
                    .refresh();
              },
              child: _Body(sections: list),
            ),
            const _BackButton(),
          ],
        ),
      ),
    );
  }
}

/// Floats over the hero rather than sitting in an app bar, so the imagery
/// runs to the very top of the screen — the treatment the Films and Studio
/// tabs already use.
///
/// Falls back to `/home` rather than doing nothing when there is nothing to
/// pop: this screen is reachable from a dashboard-configured shortcut tile
/// and from a link inside another page's copy, and a notification could
/// eventually open it cold.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 8.w,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.all(8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              // Legible over a photograph and over the flat background, which
              // a bare icon is not — the hero image can be light at the top.
              color: AppColors.brandBlack.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.smoke.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 19.w,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<PageSection> sections;

  const _Body({required this.sections});

  @override
  Widget build(BuildContext context) {
    // The first `hero` is drawn by this screen, over the mosaic, rather than
    // by the shared block — the shared one is a text stack for a page that
    // scrolls under an app bar, and this screen has no app bar.
    final heroIndex = sections.indexWhere((s) => s.kind == 'hero');
    final hero = heroIndex == -1 ? null : sections[heroIndex];
    final rest = [
      for (var i = 0; i < sections.length; i++)
        if (i != heroIndex) sections[i],
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 120.h),
      children: [
        _Hero(section: hero),
        for (final s in rest)
          if (s.kind == 'impact')
            _FiguresAndStories(section: s)
          else
            buildPageSection(s) ?? const SizedBox.shrink(),
      ],
    );
  }
}

/* ── hero ───────────────────────────────────────────────────────────── */

class _Hero extends ConsumerWidget {
  final PageSection? section;

  const _Hero({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Every picture the dashboard has, in one wall. Impact is the one screen
    // that is genuinely about all of it at once, so unlike the Films and
    // Studio heroes this does not choose a single source.
    final pools = ref.watch(headerImagePoolsProvider);
    final stories = ref.watch(impactStoriesProvider).valueOrNull ?? const [];

    final images = <String>[
      for (final s in stories)
        if (s.imageUrl.isNotEmpty) s.imageUrl,
      ...pools.values.expand((urls) => urls),
    ].where((u) => u.isNotEmpty).toList();

    final eyebrow = section?.str('eyebrow') ?? '';
    final headline = section?.str('headline') ?? '';
    final standfirst = section?.str('standfirst') ?? '';

    return SizedBox(
      height: 340.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DriftingMosaic(
              imageUrls: images,
              height: 340.h,
              // Every picture in the project at once, from a dozen sources
              // with a dozen different grades. In colour it reads as a
              // contact sheet; in grey it reads as one backdrop.
              grayscale: true,
              opacity: 1,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding.w,
                0,
                AppDimensions.pagePadding.w,
                26.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow.isNotEmpty) ...[
                    Text(
                      eyebrow.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 11.sp,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  if (headline.isNotEmpty)
                    // The last word carries the gradient, the way every other
                    // headline in the app does. Split on the final space
                    // rather than stored as segments: this one sentence is
                    // editor-written prose, and asking someone to mark up a
                    // highlight in a text box is how the Films headline got
                    // its own column.
                    SegmentedHeadline(
                      segments: _highlightLastWord(headline),
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 28.sp,
                        height: 1.2,
                        letterSpacing: -0.7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (standfirst.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      standfirst,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 13.sp,
                        height: 20 / 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Impact is not a number." → "Impact is not a " + "number."
  ///
  /// A single-word headline is left plain rather than rendered entirely in
  /// gradient, which reads as a broken heading rather than an emphasis.
  List<({String text, bool highlight})> _highlightLastWord(String line) {
    final cut = line.trimRight().lastIndexOf(' ');
    if (cut <= 0) return [(text: line, highlight: false)];
    return [
      (text: '${line.substring(0, cut)} ', highlight: false),
      (text: line.substring(cut + 1), highlight: true),
    ];
  }
}

/* ── the figures, and the stories that go with them ─────────────────── */

class _FiguresAndStories extends ConsumerWidget {
  final PageSection section;

  const _FiguresAndStories({required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(impactStatsProvider).valueOrNull ?? const [];
    final stories = ref.watch(impactStoriesProvider).valueOrNull ?? const [];

    // `PageSection` is deliberately untyped past `str` and `list` — it is the
    // shape the dashboard wrote, not a schema. A missing or nonsense `limit`
    // means "no cap" rather than "show nothing", which is the failure a bare
    // `as int` would produce on the one screen that must not lose a figure.
    final raw = section.content['limit'];
    final limit = raw is num && raw > 0 ? raw.toInt() : stats.length;
    final figures = stats.take(limit).toList();

    final title = section.str('title');

    if (figures.isEmpty && stories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (figures.isNotEmpty) ...[
          SizedBox(height: 32.h),
          if (title.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: SectionLabel(title),
            ),
            SizedBox(height: 14.h),
          ],
          // A grid, not the horizontal rail Home uses. Home is a summary
          // someone scrolls past; this is the page they came to read, and a
          // figure hidden off the right edge on the page about the figures
          // is the wrong trade.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final stat in figures) _FigureCard(stat: stat),
              ],
            ),
          ),
        ],
        if (stories.isNotEmpty) ...[
          SizedBox(height: 32.h),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: SectionLabel(
              AppLocalizations.of(context)!.impactStoriesLabel,
            ),
          ),
          SizedBox(height: 14.h),
          for (final story in stories)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding.w,
                0,
                AppDimensions.pagePadding.w,
                10.h,
              ),
              child: _StoryCard(story: story),
            ),
        ],
      ],
    );
  }
}

/// Two to a row, so a three-figure page fills the width instead of leaving a
/// column of white space beside it.
class _FigureCard extends StatelessWidget {
  final ImpactStat stat;

  const _FigureCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final width = (1.sw - (AppDimensions.pagePadding.w * 2) - 10.w) / 2;

    return SizedBox(
      width: width,
      height: 118.h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.cardSurface),
            // A figure with no photograph sits on the flat surface colour. A
            // missing picture must not become a missing statistic.
            if (stat.imageUrl.isNotEmpty)
              AppNetworkImage(url: stat.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.brandBlack.withValues(alpha: 0.92),
                    AppColors.brandBlack.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.display,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24.sp,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final ImpactStory story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (story.imageUrl.isNotEmpty)
            SizedBox(
              height: 150.h,
              width: double.infinity,
              child: AppNetworkImage(url: story.imageUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (story.description.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    story.description,
                    style: TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: 12.sp,
                      height: 19 / 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ── loading ────────────────────────────────────────────────────────── */

class _ImpactSkeleton extends StatelessWidget {
  const _ImpactSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double h, double w, [double r = 4]) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(r.r),
          ),
        );

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(340.h, double.infinity, 0),
          SizedBox(height: 28.h),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(14.h, 100.w),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(child: block(118.h, double.infinity, 6)),
                    SizedBox(width: 10.w),
                    Expanded(child: block(118.h, double.infinity, 6)),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(child: block(118.h, double.infinity, 6)),
                    SizedBox(width: 10.w),
                    Expanded(child: block(118.h, double.infinity, 6)),
                  ],
                ),
                SizedBox(height: 28.h),
                block(210.h, double.infinity, 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
