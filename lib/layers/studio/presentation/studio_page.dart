import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/widgets/detail_section.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/app/widgets/list_preview.dart';
import 'package:dsh_mobile/app/widgets/section_app_bar.dart';
import 'package:dsh_mobile/app/widgets/section_header_body.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_filter_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_capabilities.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_project_card.dart';

/// The Studio tab — Figma `2219:1309`.
///
/// The format filter used to be `setState` on this widget. It is a provider
/// now, shared with `/studio/all`, so narrowing here and then pressing "See
/// all" arrives at the narrowed list rather than at everything.
class StudioPage extends ConsumerWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(studioListProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: projectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => SafeArea(
          child: ErrorRetryWidget(
            message: error is Failure ? error.message : l10n.studioLoadError,
            onRetry: () => ref.read(studioListProvider.notifier).refresh(),
          ),
        ),
        data: (projects) => RefreshIndicator(
          color: AppColors.mainBlue,
          backgroundColor: AppColors.cardSurface,
          onRefresh: () => ref.read(studioListProvider.notifier).refresh(),
          child: _StudioContent(projects: projects),
        ),
      ),
    );
  }
}

class _StudioContent extends ConsumerWidget {
  final List<StudioProject> projects;

  const _StudioContent({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (projects.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          EmptyStateWidget(
            icon: Icons.podcasts_outlined,
            title: l10n.studioEmptyTitle,
            subtitle: l10n.studioEmptyBody,
          ),
        ],
      );
    }

    // Ongoing work leads when there is any; otherwise the newest project does.
    final featured = projects.firstWhere(
      (p) => p.status == StudioStatus.ongoing,
      orElse: () => projects.first,
    );

    final filter = ref.watch(studioFilterControllerProvider);
    final filterCtl = ref.read(studioFilterControllerProvider.notifier);

    final matches = filter.apply(projects);
    final preview = matches.take(kLibraryPreview).toList();

    final cardWidth = MediaQuery.sizeOf(context).width - 40.w;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // The hero lives inside the app bar, so the title and its two icons
        // are transparent over the imagery at rest and stay at the top once
        // it has scrolled away.
        SectionSliverAppBar(
          title: l10n.studioTab,
          // 400, not 330. Studio's hero carries a headline, a paragraph AND
          // two buttons — a third more content than the Films hero — and at
          // 330 the buttons fell outside the flexible space entirely. Clipping
          // now stops that painting over the list; this is what stops it being
          // cut off in the first place.
          expandedHeight: 400.h,
          background: const _Hero(),
          onSearch: () => context.push('/studio/search'),
          onFilter: () => context.push('/studio/search?filter=1'),
          activeFilters: filter.activeCount,
        ),

        SliverToBoxAdapter(
          child: DetailSection(
            labelStyle: DetailSection.studioLabel(),
            label: l10n.studioWhatWeDo,
            child: StudioCapabilityRow(
              onSelect: (c) => StudioCapabilitySheet.show(
                context,
                capability: c,
                imageUrl: _imageFor(c),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: DetailSection(
            labelStyle: DetailSection.studioLabel(),
            label: l10n.studioFeaturedProject,
            child: StudioProjectCard(
              project: featured,
              width: cardWidth,
              emphasised: true,
              onTap: () => context.push('/studio/${featured.slug}'),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: _LibraryHeader()),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            12.h,
            AppDimensions.pagePadding.w,
            0,
          ),
          sliver: preview.isEmpty
              // A filter that matches nothing is a normal outcome, not an
              // error — say so, and carry the way out with it.
              ? SliverToBoxAdapter(
                  child: NoFilterMatches(onClear: filterCtl.clear),
                )
              : SliverList.separated(
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, i) => StudioProjectCard(
                    project: preview[i],
                    width: cardWidth,
                    onTap: () => context.push('/studio/${preview[i].slug}'),
                  ),
                ),
        ),

        if (matches.length > preview.length)
          SliverToBoxAdapter(
            child: SeeAllButton(onTap: () => context.push('/studio/all')),
          ),

        const SliverToBoxAdapter(child: _Footer()),
        // Clears the floating tab bar.
        SliverToBoxAdapter(child: SizedBox(height: 110.h)),
      ],
    );
  }

  /// A cover from a project in the capability's format, so the sheet is
  /// illustrated by the Studio's own work rather than a bundled stock image.
  String? _imageFor(StudioCapability capability) {
    final format = capability.illustratedBy;

    final candidates =
        format == null ? projects : projects.where((p) => p.format == format);

    for (final p in candidates) {
      if (p.cardImageUrl.isNotEmpty) return p.cardImageUrl;
    }
    // Nothing in that format yet — fall back to any cover before giving up.
    for (final p in projects) {
      if (p.cardImageUrl.isNotEmpty) return p.cardImageUrl;
    }
    return null;
  }
}

/// The mosaic, the headline and the two outlined actions. No title row of its
/// own any more — that moved into [SectionSliverAppBar], which draws this as
/// its background.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Studio is the section this mattered most for: the site showed a Figma
    // export here while the app showed the real project covers — one section,
    // two different walls. Both read this setting now.
    final header =
        ref.watch(sectionHeaderProvider(SectionHeaderKey.studio)).valueOrNull ??
            const SectionHeader();

    final images = header.resolve(ref.watch(headerImagePoolsProvider));

    return SizedBox(
      height: 330.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DriftingMosaic(
              imageUrls: images,
              height: 330.h,
              rowCount: 2,
              // Grey, like the Films and Impact walls — see DriftingMosaic.
              grayscale: true,
              opacity: 1,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 20.h,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The words come from the dashboard — the same
                  // `studio_header` row the website reads. Studio's headline
                  // has three parts, not two: "Stories that / refuse to /
                  // disappear", with the middle carrying the gradient.
                  //
                  // The app's translation is the fallback for a header nobody
                  // has written, and the only version that exists in Arabic
                  // and Portuguese until someone writes one.
                  // Two lines, auto-sized down to fit. The hero is a fixed box
                  // with a standfirst and two buttons underneath; a third line
                  // pushes them off the image.
                  SegmentedHeadline(
                    segments: _headlineSegments(header, l10n),
                    maxLines: 2,
                    minFontSize: 15,
                    style: TextStyle(
                      color: AppColors.smoke,
                      // Figma 2219:1438 — same treatment as the Films hero.
                      fontSize: 27.sp,
                      height: 1.22,
                      letterSpacing: -0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // One line plus "See more" — the same component the Films
                  // hero uses, which is the point: Studio used to print the
                  // paragraph in full while Films truncated its own.
                  SectionHeaderBody(
                    header: header,
                    fallbackBody: l10n.studioHeroBody,
                    headlineSegments: _headlineSegments(header, l10n),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      _OutlinedAction(label: l10n.studioExploreWork),
                      SizedBox(width: 8.w),
                      _OutlinedAction(label: l10n.studioGetInTouch),
                    ],
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

/// The headline's runs, from the dashboard or from the app's own translation.
///
/// Shared by the hero and the sheet behind "See more" so the two cannot drift
/// apart — the sheet opens with the words that were tapped.
///
/// Studio's headline has three parts where Films has two: "Stories that /
/// refuse to / disappear", with the middle run carrying the gradient.
List<({String text, bool highlight})> _headlineSegments(
  SectionHeader header,
  AppLocalizations l10n,
) {
  if (header.hasTitle) {
    return [
      if (header.titleNormal.isNotEmpty)
        (text: '${header.titleNormal} ', highlight: false),
      if (header.titleColored.isNotEmpty)
        (text: header.titleColored, highlight: true),
      if (header.titleAfter.isNotEmpty)
        (text: ' ${header.titleAfter}', highlight: false),
    ];
  }

  return [
    (text: '${l10n.studioHeroTitle} ', highlight: false),
    (text: l10n.studioHeroHighlight, highlight: true),
  ];
}

class _OutlinedAction extends StatelessWidget {
  final String label;

  const _OutlinedAction({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(3.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.20),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.smoke,
          fontSize: 12.sp,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "Studio Library" and the way into the full one.
///
/// The horizontal chip row that used to live here is gone: it carried only
/// the format facet, so the status facet the website filters on had no
/// control at all on the phone, and five chips in a scroll strip meant the
/// last two were never seen. Both facets are in the filter sheet now, behind
/// the button in the bar directly below this heading.
///
/// "View all" changed meaning with it. It used to clear the format filter,
/// which is the same action as the "All" chip it sat beside; it opens the
/// full library now, which is what the words say.
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        28.h,
        AppDimensions.pagePadding.w,
        14.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.studioLibrary,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 14.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/studio/all'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  l10n.studioViewAll,
                  style: TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 11.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.lightGrey,
                  size: 13.w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 44.h),
      child: Column(
        children: [
          Text(
            'DSH',
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 13.sp,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            AppLocalizations.of(context)!
                .studioFooter('${DateTime.now().year}'),
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 9.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
