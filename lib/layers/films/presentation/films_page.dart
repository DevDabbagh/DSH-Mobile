import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/app/widgets/list_preview.dart';
import 'package:dsh_mobile/app/widgets/section_app_bar.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_filter_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_list_card.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_poster_card.dart';

class FilmsPage extends ConsumerWidget {
  const FilmsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmsAsync = ref.watch(filmsListProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: filmsAsync.when(
        loading: () => const _FilmsSkeleton(),
        error: (error, _) => SafeArea(
          child: ErrorRetryWidget(
            message: error is Failure
                ? error.message
                : AppLocalizations.of(context)!.filmsLoadError,
            onRetry: () => ref.read(filmsListProvider.notifier).refresh(),
          ),
        ),
        data: (films) => RefreshIndicator(
          color: AppColors.mainBlue,
          backgroundColor: AppColors.cardSurface,
          onRefresh: () => ref.read(filmsListProvider.notifier).refresh(),
          child: _FilmsContent(films: films),
        ),
      ),
    );
  }
}

class _FilmsContent extends ConsumerWidget {
  final List<Film> films;

  const _FilmsContent({required this.films});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (films.isEmpty) {
      // Still scrollable, so pull-to-refresh works from the empty state —
      // otherwise there is no way to retry once content is published.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          EmptyStateWidget(
            icon: Icons.movie_outlined,
            title: l10n.filmsEmptyTitle,
            subtitle: l10n.filmsEmptyBody,
          ),
        ],
      );
    }

    final filter = ref.watch(filmsFilterControllerProvider);
    final filterCtl = ref.read(filmsFilterControllerProvider.notifier);

    final featured = films.where((f) => f.isFeatured).toList();
    // Every film is worth surfacing; if nobody has flagged a favourite the
    // rail shows the newest few rather than disappearing.
    final rail = featured.isNotEmpty ? featured : films.take(6).toList();

    final matches = filter.apply(films);
    final preview = matches.take(kLibraryPreview).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // The hero lives inside the app bar, so the title and its two icons
        // are transparent over the imagery at rest and stay at the top once
        // it has scrolled away.
        SectionSliverAppBar(
          title: l10n.filmsTab,
          expandedHeight: 300.h,
          background: const _Hero(),
          onSearch: () => context.push('/films/search'),
          onFilter: () => context.push('/films/search?filter=1'),
          activeFilters: filter.activeCount,
        ),
        SliverToBoxAdapter(child: _FeaturedRail(films: rail)),
        SliverToBoxAdapter(child: const _LibraryHeader()),

        if (preview.isEmpty)
          SliverToBoxAdapter(
            child: NoFilterMatches(onClear: filterCtl.clear),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              12.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            sliver: SliverList.separated(
              itemCount: preview.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, i) => FilmListCard(
                film: preview[i],
                onTap: () => context.push('/films/${preview[i].slug}'),
              ),
            ),
          ),

        // Only when there is more behind it. "See all" under a list that is
        // already all of it is a button that appears to do nothing.
        if (matches.length > preview.length)
          SliverToBoxAdapter(
            child: SeeAllButton(onTap: () => context.push('/films/all')),
          ),

        // Clears the floating tab bar.
        SliverToBoxAdapter(child: SizedBox(height: 120.h)),
      ],
    );
  }
}

/// The mosaic and the headline. No title row of its own any more — that moved
/// into [SectionSliverAppBar], which draws this as its background.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The wall the dashboard chose. Defaults to the film posters, which is
    // what this always did — the difference is that an editor can now say
    // otherwise, and the website obeys the same setting.
    final header =
        ref.watch(sectionHeaderProvider(SectionHeaderKey.films)).valueOrNull ??
            const SectionHeader();

    final images = header.resolve(ref.watch(headerImagePoolsProvider));

    return SizedBox(
      height: 300.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DriftingMosaic(
              imageUrls: images,
              height: 300.h,
              // Grey, like Impact and like the onboarding wall. A dozen
              // posters at a dozen different grades read as a contact sheet
              // in colour; desaturating is what makes a mixed set cohere
              // into one backdrop for the headline.
              grayscale: true,
              // The tint IS the darkening — see DriftingMosaic._siteTint.
              opacity: 1,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 22.h,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: const _Headline(),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cinema that **refuses silence.**" — the closing words carry the brand
/// gradient.
///
/// Uses the shared [SegmentedHeadline] so this reads identically to the
/// onboarding headlines; a one-off ShaderMask over the whole line would tint
/// the plain half too.
class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedHeadline(
      segments: [
        (text: '${l10n.filmsHeroTitle} ', highlight: false),
        (text: l10n.filmsHeroHighlight, highlight: true),
      ],
      style: TextStyle(
        color: AppColors.smoke,
        fontSize: 27.sp,
        height: 1.22,
        letterSpacing: -0.7,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _FeaturedRail extends StatelessWidget {
  final List<Film> films;

  const _FeaturedRail({required this.films});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            24.h,
            AppDimensions.pagePadding.w,
            0,
          ),
          // The "N titles" counter that used to sit at the end of this row is
          // gone with the "1 film" under Library, and for the same reason: on
          // a young catalogue it announced how little there was, and it was
          // the first thing the eye landed on.
          child: Text(
            AppLocalizations.of(context)!.filmsFeatured,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 14.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: FilmPosterCard.height.h + 4.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            itemCount: films.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, i) => FilmPosterCard(
              film: films[i],
              emphasised: i == 0,
              onTap: () => context.push('/films/${films[i].slug}'),
              // The trailer button opens the film too; the player lives on
              // the detail page, so there is nothing separate to launch yet.
              onWatchTrailer: () => context.push('/films/${films[i].slug}'),
            ),
          ),
        ),
      ],
    );
  }
}

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
            l10n.filmsLibrary,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 14.sp,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/films/all'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  l10n.seeAll,
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

/// Shown while the first load is in flight. Mirrors the real layout — hero
/// block, a rail of cards, a couple of list rows — so the page does not jump
/// when the content arrives.
class _FilmsSkeleton extends StatelessWidget {
  const _FilmsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Block(height: 300.h, width: double.infinity, radius: 0),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: _Block(height: 16.h, width: 120.w),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: FilmPosterCard.height.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (_, __) => _Block(
                height: FilmPosterCard.height.h,
                width: FilmPosterCard.width.w,
                radius: 6,
              ),
            ),
          ),
          SizedBox(height: 28.h),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(height: 16.h, width: 80.w),
                SizedBox(height: 12.h),
                _Block(height: 42.h, width: double.infinity, radius: 4),
                SizedBox(height: 12.h),
                for (var i = 0; i < 3; i++) ...[
                  _Block(
                    height: FilmListCard.height.h,
                    width: double.infinity,
                    radius: 6,
                  ),
                  SizedBox(height: 10.h),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const _Block({
    required this.height,
    required this.width,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(radius.r),
      ),
    );
  }
}
