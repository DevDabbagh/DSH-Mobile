import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/detail_section.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/app/widgets/list_preview.dart';
import 'package:dsh_mobile/app/widgets/section_app_bar.dart';
import 'package:dsh_mobile/app/widgets/section_header_body.dart';
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
          // The same wall as Studio. Films was 100 shorter, which made the two
          // tabs feel like different templates when you swapped between them.
          expandedHeight: 360.h,
          background: const _Hero(),
          onSearch: () => context.push('/films/search'),
          onFilter: () => context.push('/films/search?filter=1'),
          activeFilters: filter.activeCount,
        ),
        SliverToBoxAdapter(child: _FeaturedRail(films: rail)),
        const SliverToBoxAdapter(child: _LibraryHeader()),

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
    final l10n = AppLocalizations.of(context)!;

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
              // The website's pink wash over this same hero, entering from
              // the outer edge. Without it the app's Films hero was the only
              // grade of this wall on either surface with no colour in it.
              tint: DriftingMosaic.kFilmsHeroTint,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Headline(header: header),
                  SizedBox(height: 12.h),
                  // The paragraph under the headline.
                  //
                  // `SectionHeader` has parsed `description` since it was
                  // written and this screen simply never drew it — so an
                  // editor could fill in "Header Description" on the Films
                  // tab, watch it appear on the website, and find nothing had
                  // changed in the app. Studio was rendering its copy of the
                  // same field all along, which is why the gap survived.
                  SectionHeaderBody(
                    header: header,
                    fallbackBody: l10n.filmsHeroBody,
                    headlineSegments: _headlineSegments(header, l10n),
                  ),
                  SizedBox(height: 14.h),
                  // The website's pair. They set the form filter rather than
                  // navigating: the listing is on this same screen, so a link
                  // would be a link to where the reader already is.
                  const _ExploreButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero headline — the closing words carry the brand gradient.
///
/// **The words come from the dashboard**, the same `films_header` row the
/// website reads, so an editor rewrites the headline once. The app's own
/// translation is the fallback for a header nobody has written yet — and it
/// is also the only version that exists in Arabic and Portuguese until
/// someone does.
///
/// Uses the shared [SegmentedHeadline] so this reads identically to the
/// onboarding headlines; a one-off ShaderMask over the whole line would tint
/// the plain half too.
/// The headline's runs, from the dashboard or from the app's own translation.
///
/// Shared by the hero and the sheet behind "See more" so the two cannot drift
/// — the sheet exists to show the full text, and a sheet that opened with a
/// different headline from the one that was tapped would be worse than no
/// sheet.
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
    ];
  }

  return [
    (text: '${l10n.filmsHeroTitle} ', highlight: false),
    (text: l10n.filmsHeroHighlight, highlight: true),
  ];
}

class _Headline extends StatelessWidget {
  final SectionHeader header;

  const _Headline({required this.header});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedHeadline(
      segments: _headlineSegments(header, l10n),
      // Two lines, shrinking to fit rather than wrapping to three.
      //
      // The hero is a fixed 300-pixel box holding a headline, a line of
      // description and two buttons. A third line of headline does not push
      // the buttons down — it pushes them off the image onto the black below,
      // which is what the last screenshot showed.
      maxLines: 2,
      minFontSize: 15,
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

/// "Explore documentaries" · "Explore fiction" — the website's hero pair.
///
/// They set the form filter rather than navigating. On the site the listing
/// is further down the same page and these scroll to it; here the listing is
/// on this screen already, so a link would lead to where the reader is
/// standing. Pressing one narrows what is below.
///
/// Pressing the active one again clears it — a filter you can turn on and not
/// off is a trap, and there is no visible "all" control up here to escape to.
class _ExploreButtons extends ConsumerWidget {
  const _ExploreButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(filmsFilterControllerProvider).form;

    void toggle(FilmForm form) => ref
        .read(filmsFilterControllerProvider.notifier)
        .setForm(active == form ? null : form);

    // The website's own labels — "Explore documentaries" / "Explore fiction".
    //
    // These were showing the bare form names, "Documentary" and "Fiction",
    // which are the words the CHIPS use further down the same screen. Two
    // controls with the same label doing different things is worse than a
    // longer button: the site's wording says these are a way in, not a filter
    // you are looking at.
    return Row(
      children: [
        Flexible(
          child: _ExploreButton(
            label: l10n.filmsExploreDocumentaries,
            selected: active == FilmForm.documentary,
            onTap: () => toggle(FilmForm.documentary),
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: _ExploreButton(
            label: l10n.filmsExploreFiction,
            selected: active == FilmForm.fiction,
            onTap: () => toggle(FilmForm.fiction),
          ),
        ),
      ],
    );
  }
}

class _ExploreButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExploreButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Studio's exact glass pill — a knocked-back fill over the
          // photographs rather than a solid one, so the wall still reads
          // through it.
          //
          // Films had its own dimmer version of this (0.2 fill, 0.55 text)
          // and a purple state when a form was chosen, which made the same
          // control look like two different components across two tabs. The
          // selected state stays — it is what these buttons DO — but it is
          // now the brand blue over the same glass, not a separate palette.
          color: selected
              ? AppColors.mainPurple.withValues(alpha: 0.30)
              : AppColors.darkBackground.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: selected
                ? AppColors.mainPurple.withValues(alpha: 0.70)
                : AppColors.smoke.withValues(alpha: 0.20),
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.smoke,
            fontSize: 12.sp,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          //
          // Studio's eyebrow, exactly — upper case, 11sp, letter-spaced, and
          // knocked back to 35% white. It was 14sp semibold solid white here,
          // the same weight as "Library" underneath it, so a rail label and a
          // section heading read as two headings of equal rank. This one is a
          // caption over the row it introduces; the white heading below is
          // the one that ranks.
          child: Text(
            AppLocalizations.of(context)!.filmsFeatured.toUpperCase(),
            style: DetailSection.studioLabel(),
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
          _Block(height: 400.h, width: double.infinity, radius: 0),
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
