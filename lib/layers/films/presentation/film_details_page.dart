import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/app/widgets/detail_section.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_badges.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_detail_blocks.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_poster_card.dart';

/// One film, in full — Figma `2170:1209`.
///
/// Every block below the hero is gated on its own data. A film with no
/// festivals, no screenings and no press shows a synopsis and stops, rather
/// than a column of empty headings; the sections appear as editors fill them
/// in from the dashboard.
class FilmDetailsPage extends ConsumerWidget {
  final String slug;

  const FilmDetailsPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filmAsync = ref.watch(filmBySlugProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: filmAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => SafeArea(
          child: ErrorRetryWidget(
            message: error is Failure ? error.message : l10n.filmsLoadError,
            onRetry: () => ref.invalidate(filmBySlugProvider(slug)),
          ),
        ),
        data: (film) {
          if (film == null) {
            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: EmptyStateWidget(
                      icon: Icons.movie_outlined,
                      title: l10n.filmNotFound,
                    ),
                  ),
                  const _BackButton(),
                ],
              ),
            );
          }
          return _FilmBody(film: film);
        },
      ),
    );
  }
}

class _FilmBody extends ConsumerWidget {
  final Film film;

  const _FilmBody({required this.film});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // "More from DSH" comes out of the already-loaded listing, so opening a
    // film never costs a second query.
    final others = (ref.watch(filmsListProvider).valueOrNull ?? const <Film>[])
        .where((f) => f.slug != film.slug)
        .take(6)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(film: film)),
        SliverToBoxAdapter(child: _Meta(film: film)),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionSynopsis,
            child: _synopsis == null ? null : ExpandableText(text: _synopsis!),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionEditorial,
            child: film.editorialContext.trim().isEmpty
                ? null
                : EditorialContextCard(text: film.editorialContext),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionCredits,
            child: _credits(l10n),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionStills,
            bleed: true,
            child: film.detailsSliders.isEmpty
                ? null
                : _Stills(urls: film.detailsSliders),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionFestivals,
            child: film.festivals.isEmpty
                ? null
                : FestivalGrid(festivals: film.festivals),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionScreenings,
            child: film.screenings.isEmpty
                ? null
                : Column(
                    children: [
                      for (final s in film.screenings) ...[
                        ScreeningRow(screening: s),
                        SizedBox(height: 10.h),
                      ],
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionPress,
            child: film.pressQuotes.isEmpty
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final q in film.pressQuotes) ...[
                        PressQuoteBlock(quote: q),
                        SizedBox(height: 18.h),
                      ],
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              28.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            child: SupportCard(
              onTap: () {
                // NO SIGN-IN GATE, deliberately — and this used to have one.
                //
                // The web has never required an account to give: the donor
                // chooses on the thank-you screen whether to be named, and
                // migration 020 links guest gifts to an account if they sign
                // up later with the same email. Requiring sign-in here made
                // the app refuse donations the website accepts, which costs
                // DSH money and asks someone to prove who they are before
                // they may give something away.
                //
                // The same three parameters the website puts in the query
                // string. They travel to Stripe as metadata, which is what
                // lets the dashboard report what this film raised — drop one
                // and the donation still succeeds but is attributed to
                // nothing.
                context.push(
                  Uri(
                    path: '/support',
                    queryParameters: {
                      'fundType': 'film',
                      'fundSlug': film.slug,
                      'fundTitle': film.title,
                    },
                  ).toString(),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailSection(
            label: l10n.filmSectionMore,
            bleed: true,
            child: others.isEmpty ? null : _MoreRail(films: others),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 60.h)),
      ],
    );
  }

  /// The long synopsis when there is one, otherwise the short — never both,
  /// and never an empty section.
  String? get _synopsis {
    final long = film.synopsisLong.trim();
    if (long.isNotEmpty) return long;
    final short = film.synopsisShort.trim();
    return short.isEmpty ? null : short;
  }

  /// Only the credit fields the database actually stores. The Figma also
  /// shows Cinematographer, Editor and Sound Design; those columns do not
  /// exist on `films` yet, so they are left out rather than faked.
  Widget? _credits(AppLocalizations l10n) {
    final rows = <DetailRow>[
      if (film.credits.direction.isNotEmpty)
        DetailRow(
          label: l10n.filmCreditDirector,
          value: film.credits.direction,
        ),
      if (film.credits.production.isNotEmpty)
        DetailRow(
          label: l10n.filmCreditProducer,
          value: film.credits.production,
        ),
      if (film.credits.coProduction.isNotEmpty)
        DetailRow(
          label: l10n.filmCreditCoProduction,
          value: film.credits.coProduction,
        ),
      if (film.credits.language.isNotEmpty)
        DetailRow(
          label: l10n.filmCreditLanguage,
          value: film.credits.language,
        ),
      if (film.credits.country.isNotEmpty)
        DetailRow(
          label: l10n.filmCreditCountry,
          value: film.credits.country,
        ),
    ];

    if (rows.isEmpty) return null;
    return Column(children: rows);
  }
}

class _Hero extends StatelessWidget {
  final Film film;

  const _Hero({required this.film});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (film.thumbnailUrl.isNotEmpty || film.posterUrl.isNotEmpty)
            AppNetworkImage(
              url: film.cardImageUrl,
              fit: BoxFit.cover,
            )
          else
            const ColoredBox(color: AppColors.mediumBackground),

          // Darkens top and bottom so the controls and the title stay legible
          // whatever the still underneath happens to be.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x990D0D0D),
                  Color(0x330D0D0D),
                  Color(0xCC0D0D0D),
                  AppColors.deepBackground,
                ],
                stops: [0.0, 0.35, 0.78, 1.0],
              ),
            ),
          ),

          const _BackButton(),

          PositionedDirectional(
            start: AppDimensions.pagePadding.w,
            end: AppDimensions.pagePadding.w,
            bottom: 18.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  FilmBadges.formLabel(
                    AppLocalizations.of(context)!,
                    film.credits,
                  ).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.purpleLight2,
                    fontSize: 8.sp,
                    height: 1.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  film.title,
                  // Figma 2170:1240 — 26/31.2 bold, and no tracking.
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 26.sp,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: AppDimensions.pagePadding.w,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            // Deep links land here with nothing to pop; send those to the
            // Films tab so the back control is never a dead button.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/films');
            }
          },
          child: Container(
            margin: EdgeInsets.only(top: 8.h),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              size: 18.w,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The band under the hero: poster, the year · duration · language line,
/// director, theme chips and the trailer button.
class _Meta extends StatelessWidget {
  final Film film;

  const _Meta({required this.film});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final facts = [
      film.credits.year,
      film.credits.duration,
      film.credits.language,
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (film.posterUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: AppNetworkImage(
                    url: film.posterUrl,
                    width: 74.w,
                    height: 100.h,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 14.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (facts.isNotEmpty)
                      Text(
                        facts,
                        style: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 11.sp,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (film.credits.direction.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          CircleAvatar(
                            // Figma 2170:1249 — 20px across.
                            radius: 10.r,
                            backgroundColor: AppColors.mediumBackground,
                            child: Text(
                              _initial(film.credits.direction),
                              style: TextStyle(
                                color: AppColors.smoke,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: Text(
                              film.credits.direction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // Figma 2170:1251 — 12px regular, white 70%.
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (film.themes.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          for (final t in film.themes) DetailChip(label: t),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (film.trailerUrl.isNotEmpty) ...[
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: Container(
                height: 42.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: AppColors.smoke.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.filmWatchTrailerFull,
                      // Figma 2170:1268 — 13/19.5 medium, plain white.
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 14.w,
                      color: AppColors.smoke,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}

class _Stills extends StatelessWidget {
  final List<String> urls;

  const _Stills({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding.w,
        ),
        itemCount: urls.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: AppNetworkImage(
            url: urls[i],
            width: 140.w,
            height: 96.h,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _MoreRail extends StatelessWidget {
  final List<Film> films;

  const _MoreRail({required this.films});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          onTap: () => context.push('/films/${films[i].slug}'),
        ),
      ),
    );
  }
}
