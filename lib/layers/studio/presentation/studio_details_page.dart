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
// The support CTA is shared with the film pages rather than duplicated: its
// copy is about supporting a project, and two copies would drift.
import 'package:dsh_mobile/layers/films/presentation/widgets/film_detail_blocks.dart'
    show SupportCard;
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_detail_blocks.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_format_label.dart';

/// One studio project with its episodes — Figma `2219:2051`.
class StudioDetailsPage extends ConsumerStatefulWidget {
  final String slug;

  const StudioDetailsPage({super.key, required this.slug});

  @override
  ConsumerState<StudioDetailsPage> createState() => _StudioDetailsPageState();
}

class _StudioDetailsPageState extends ConsumerState<StudioDetailsPage> {
  int? _season;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectAsync = ref.watch(studioProjectBySlugProvider(widget.slug));

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: projectAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => SafeArea(
          child: ErrorRetryWidget(
            message: error is Failure ? error.message : l10n.studioLoadError,
            onRetry: () =>
                ref.invalidate(studioProjectBySlugProvider(widget.slug)),
          ),
        ),
        data: (project) {
          if (project == null) {
            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: EmptyStateWidget(
                      icon: Icons.podcasts_outlined,
                      title: l10n.studioProjectNotFound,
                    ),
                  ),
                  const _BackButton(),
                ],
              ),
            );
          }
          return _ProjectBody(
            project: project,
            season: _season,
            onSeasonChanged: (s) => setState(() => _season = s),
          );
        },
      ),
    );
  }
}

class _ProjectBody extends StatelessWidget {
  final StudioProject project;
  final int? season;
  final ValueChanged<int> onSeasonChanged;

  const _ProjectBody({
    required this.project,
    required this.season,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final seasons = _seasons;
    // Nothing chosen yet — show the first season rather than an empty list.
    final activeSeason = season ?? (seasons.isEmpty ? null : seasons.first);
    final episodes = activeSeason == null
        ? project.episodes
        : project.episodes
            .where((e) => (e.season ?? 1) == activeSeason)
            .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(project: project)),
        SliverToBoxAdapter(child: _Actions(project: project)),

        if (project.stills != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding.w,
                20.h,
                AppDimensions.pagePadding.w,
                0,
              ),
              child: StillsCarousel(urls: project.stills!),
            ),
          ),

        SliverToBoxAdapter(child: _Synopsis(project: project)),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              22.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            child: StudioCreditsTable(rows: _creditRows(l10n)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              32.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            child: Text(
              l10n.studioSectionEpisodes.toUpperCase(),
              style: TextStyle(
                color: AppColors.smoke.withValues(alpha: 0.35),
                fontSize: 11.sp,
                height: 1.5,
                letterSpacing: 1.76,
              ),
            ),
          ),
        ),

        // One season needs no tabs — the row would just be a label.
        if (seasons.length > 1)
          SliverToBoxAdapter(
            child: _SeasonTabs(
              seasons: seasons,
              active: activeSeason,
              onChanged: onSeasonChanged,
            ),
          ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            18.h,
            AppDimensions.pagePadding.w,
            0,
          ),
          sliver: episodes.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    child: Text(
                      l10n.studioNoEpisodes,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 11.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, i) {
                    final e = episodes[i];
                    void open() {
                      final slug = e.slug;
                      // An episode with no slug has no page to open; the card
                      // stays inert rather than routing to a broken URL.
                      if (slug == null || slug.isEmpty) return;
                      context.push('/studio/${project.slug}/$slug');
                    }

                    return EpisodeCard(
                      episode: e,
                      onView: open,
                      onKnowMore: open,
                    );
                  },
                ),
        ),

        SliverToBoxAdapter(child: _ShareCard(project: project)),

        // The web closes this page with a full-bleed support banner
        // (`/support?fundType=studio&…`); the app had nothing, so a studio
        // project could not be funded at all. Reuses the film pages' card
        // rather than growing a second one — the copy is about supporting a
        // project, not specifically a film.
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
            child: Builder(
              builder: (context) => SupportCard(
                // No sign-in gate — see the note on the film page. Giving is
                // open to anyone; being named is the donor's own choice,
                // taken afterwards.
                onTap: () {
                  context.push(
                    Uri(
                      path: '/support',
                      queryParameters: {
                        'fundType': 'studio',
                        'fundSlug': project.slug,
                        'fundTitle': project.title,
                      },
                    ).toString(),
                  );
                },
              ),
            ),
          ),
        ),

        // Clears the floating tab bar.
        // No tab bar under this screen — it is declared outside the shell.
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }

  /// Season numbers present in the data, in order. Episodes with no season
  /// are treated as season 1, matching the database default.
  List<int> get _seasons {
    final set = <int>{for (final e in project.episodes) e.season ?? 1};
    final list = set.toList()..sort();
    return list;
  }

  List<({String label, String value})> _creditRows(AppLocalizations l10n) {
    final c = project.credits;

    return [
      if (c.production.isNotEmpty)
        (label: l10n.studioCreditProduction, value: c.production),
      if (c.coProduction.isNotEmpty)
        (label: l10n.studioCreditCoProduction, value: c.coProduction),
      if (c.hosts.isNotEmpty)
        (label: l10n.studioCreditHosts, value: c.hosts.join(', ')),
      if (c.year.isNotEmpty) (label: l10n.studioCreditYear, value: c.year),
      if (c.language.isNotEmpty)
        (label: l10n.studioCreditLanguage, value: c.language),
      if ((c.direction ?? '').isNotEmpty)
        (label: l10n.studioCreditDirection, value: c.direction!),
      (
        label: l10n.studioCreditFormat,
        // The format label falls back to the enum's own name when the project
        // has no explicit format label written.
        value: c.formatLabel?.trim().isNotEmpty == true
            ? c.formatLabel!
            : studioFormatLabel(l10n, project.format),
      ),
      if ((c.country ?? '').isNotEmpty)
        (label: l10n.studioCreditCountry, value: c.country!),
      if ((c.duration ?? '').isNotEmpty)
        (label: l10n.studioCreditDuration, value: c.duration!),
      if (c.partners.isNotEmpty)
        (label: l10n.studioCreditPartners, value: c.partners.join(', ')),
    ];
  }
}

class _Hero extends StatelessWidget {
  final StudioProject project;

  const _Hero({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 290.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (project.coverUrl.isNotEmpty || project.thumbnailUrl.isNotEmpty)
            // Knocked well back: this is a backdrop for the title, not a
            // picture in its own right — the stills carousel is that.
            Opacity(
              opacity: 0.30,
              child: AppNetworkImage(
                url: project.coverUrl.isNotEmpty
                    ? project.coverUrl
                    : project.thumbnailUrl,
                fit: BoxFit.cover,
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.deepBackground,
                  Color(0x730D0D0D),
                  Color(0x000D0D0D),
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
          const _BackButton(),
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2.r),
                      border: Border.all(
                        color: AppColors.smoke.withValues(alpha: 0.14),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      studioFormatLabel(l10n, project.format).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 9.sp,
                        height: 1.5,
                        letterSpacing: 1.26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    project.title,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 25.sp,
                      height: 1.24,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (project.oneLineDescription.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      project.oneLineDescription,
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 13.sp,
                        height: 1.46,
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
}

/// The same disc the Impact screen uses, so the way back is one shape
/// wherever you are.
///
/// It was a "‹ Studio" text link. Two problems with that, and the second is
/// the one that shows: the hero photograph is an editor's upload and can be
/// light at the top, where bare white type disappears — and the label named
/// the screen behind it, so the control changed wording depending on where
/// the reader had come from.
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
          // Falls back to the listing rather than doing nothing: this screen
          // is reachable from a link in another page's copy and, eventually,
          // from a notification on a cold start — both arrive with an empty
          // stack, where `pop()` is a button that does not respond.
          onTap: () => context.canPop() ? context.pop() : context.go('/studio'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: EdgeInsets.all(8.w),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.brandBlack.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.smoke.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
            // Mirrors in Arabic, where back is to the right.
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

class _Actions extends StatelessWidget {
  final StudioProject project;

  const _Actions({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // The website points all three enquiry buttons at its About page — there
    // is no enquiry form yet on either surface. Matching that rather than
    // inventing a destination keeps the two in step; when a real contact
    // route exists, this is the one place to change.
    void enquire() => context.push('/about');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        16.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        children: [
          _Action(
            label: l10n.studioExploreEpisodes,
            filled: true,
            onTap: () {},
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: l10n.studioRequestScreener,
                  onTap: enquire,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _Action(
                  label: l10n.studioRequestScreening,
                  onTap: enquire,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _Action(
            label: l10n.studioContactDistribution,
            onTap: enquire,
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _Action({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: filled ? 38.h : 34.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.smoke.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: filled ? 0.10 : 0.12),
            width: filled ? 1.2 : 0.6,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: filled ? AppColors.smoke : AppColors.lightGrey,
            fontSize: filled ? 13.sp : 11.sp,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Synopsis extends StatelessWidget {
  final StudioProject project;

  const _Synopsis({required this.project});

  @override
  Widget build(BuildContext context) {
    final short = project.synopsisShort.trim();
    final long = project.synopsisLong.trim();
    final editorial = project.editorialContext.trim();

    if (short.isEmpty && long.isEmpty && editorial.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        24.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (short.isNotEmpty)
            Text(
              short,
              style: TextStyle(
                color: AppColors.smoke,
                fontSize: 15.sp,
                height: 1.53,
              ),
            ),
          if (long.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              long,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 13.sp,
                height: 1.62,
              ),
            ),
          ],
          if (editorial.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsetsDirectional.only(start: 14.w),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  // Directional, so the rule sits on the reading edge in
                  // Arabic instead of hanging off the far side.
                  start: BorderSide(
                    color: AppColors.smoke.withValues(alpha: 0.14),
                    width: 1.85,
                  ),
                ),
              ),
              child: Text(
                editorial,
                style: TextStyle(
                  color: AppColors.mediumGrey,
                  fontSize: 13.sp,
                  height: 1.54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeasonTabs extends StatelessWidget {
  final List<int> seasons;
  final int? active;
  final ValueChanged<int> onChanged;

  const _SeasonTabs({
    required this.seasons,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.smoke.withValues(alpha: 0.06),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final s in seasons)
            GestureDetector(
              onTap: () => onChanged(s),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: EdgeInsetsDirectional.only(end: 20.w),
                padding: EdgeInsets.only(bottom: 11.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: s == active ? AppColors.smoke : Colors.transparent,
                      width: 1.85,
                    ),
                  ),
                ),
                child: Text(
                  l10n.studioSeasonNumber('$s'),
                  style: TextStyle(
                    color: s == active ? AppColors.smoke : AppColors.mediumGrey,
                    fontSize: 13.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final StudioProject project;

  const _ShareCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        28.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.studioShareProject,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
            Container(
              height: 32.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.r),
                border: Border.all(
                  color: AppColors.smoke.withValues(alpha: 0.10),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ios_share,
                    size: 12.w,
                    color: AppColors.smoke,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.studioShare,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 12.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
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
