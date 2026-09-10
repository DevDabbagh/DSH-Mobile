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
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_detail_blocks.dart';

/// One episode — Figma `2219:2356`.
///
/// Loads the parent project and reads the episode out of it, so arriving here
/// from the project page costs no extra query and the "more episodes" list is
/// already in hand.
class EpisodeDetailsPage extends ConsumerWidget {
  final String projectSlug;
  final String episodeSlug;

  const EpisodeDetailsPage({
    super.key,
    required this.projectSlug,
    required this.episodeSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projectAsync = ref.watch(studioProjectBySlugProvider(projectSlug));

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
                ref.invalidate(studioProjectBySlugProvider(projectSlug)),
          ),
        ),
        data: (project) {
          final episode = project?.episodeBySlug(episodeSlug);

          if (project == null || episode == null) {
            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: EmptyStateWidget(
                      icon: Icons.play_circle_outline,
                      title: l10n.studioEpisodeNotFound,
                    ),
                  ),
                  _BackBar(label: project?.title ?? l10n.studioTab),
                ],
              ),
            );
          }

          return _EpisodeBody(project: project, episode: episode);
        },
      ),
    );
  }
}

class _EpisodeBody extends StatelessWidget {
  final StudioProject project;
  final StudioEpisode episode;

  const _EpisodeBody({required this.project, required this.episode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final others =
        project.episodes.where((e) => e.slug != episode.slug).take(4).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(project: project, episode: episode)),
        if (episode.quotes != null)
          SliverToBoxAdapter(child: _PullQuotes(quotes: episode.quotes!)),
        if (episode.gallery != null)
          SliverToBoxAdapter(
            child: _Section(
              label: l10n.studioSectionGallery,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding.w,
                ),
                child: StillsCarousel(urls: episode.gallery!),
              ),
            ),
          ),
        if (others.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              label: l10n.studioMoreEpisodes,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding.w,
                ),
                child: Column(
                  children: [
                    for (final e in others) ...[
                      _MiniEpisodeRow(
                        episode: e,
                        onTap: () {
                          final slug = e.slug;
                          if (slug == null || slug.isEmpty) return;
                          // replace, not push: hopping between episodes should
                          // not build a back stack the user has to unwind.
                          context.pushReplacement(
                            '/studio/${project.slug}/$slug',
                          );
                        },
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: _Footer()),
        // No tab bar under this screen — it is declared outside the shell.
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final StudioProject project;
  final StudioEpisode episode;

  const _Hero({required this.project, required this.episode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = (episode.imageUrl ?? '').isNotEmpty
        ? episode.imageUrl!
        : project.cardImageUrl;

    return SizedBox(
      height: 330.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            AppNetworkImage(
              url: image,
              fit: BoxFit.cover,
            )
          else
            const ColoredBox(color: AppColors.mediumBackground),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB30D0D0D),
                  Color(0x730D0D0D),
                  Color(0xE60D0D0D),
                  AppColors.deepBackground,
                ],
                stops: [0.0, 0.3, 0.8, 1.0],
              ),
            ),
          ),
          _BackBar(label: project.title),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 18.h,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Breadcrumbs(project: project, episode: episode),
                  SizedBox(height: 8.h),
                  Text(
                    episode.title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22.sp,
                      height: 1.25,
                      letterSpacing: -0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((episode.subtitle ?? '').isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      episode.subtitle!,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (episode.description.trim().isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      episode.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 12.sp,
                        height: 1.55,
                      ),
                    ),
                  ],
                  if (episode.hasVideo) ...[
                    SizedBox(height: 14.h),
                    _WatchButton(label: l10n.studioViewEpisode),
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

/// "THE WITNESS ARCHIVE › EPISODE 1 › SEASON 1"
class _Breadcrumbs extends StatelessWidget {
  final StudioProject project;
  final StudioEpisode episode;

  const _Breadcrumbs({required this.project, required this.episode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final crumbs = <String>[
      project.title,
      if (episode.number != null) l10n.studioEpisodeNumber('${episode.number}'),
      if (episode.season != null) l10n.studioSeasonNumber('${episode.season}'),
    ];

    return Wrap(
      spacing: 5.w,
      runSpacing: 4.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0)
            Icon(
              // Directional chevron so the trail reads right-to-left in Arabic.
              Icons.chevron_right,
              size: 11.w,
              color: AppColors.mediumGrey,
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppColors.deepBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2.r),
              border: Border.all(
                color: AppColors.smoke.withValues(alpha: 0.14),
                width: 0.6,
              ),
            ),
            child: Text(
              crumbs[i].toUpperCase(),
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 8.sp,
                height: 1.5,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WatchButton extends StatelessWidget {
  final String label;

  const _WatchButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.deepBackground.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(3.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 13.w, color: AppColors.smoke),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 12.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  final String label;

  const _BackBar({required this.label});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 16.w,
      end: 16.w,
      top: 0,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/studio');
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 15.w, color: AppColors.smoke),
                SizedBox(width: 7.w),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 13.sp,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PullQuotes extends StatelessWidget {
  final List<String> quotes;

  const _PullQuotes({required this.quotes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        26.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final q in quotes)
            Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsetsDirectional.only(start: 14.w),
              decoration: const BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: AppColors.mainPurple, width: 2),
                ),
              ),
              child: Text(
                '“$q”',
                style: TextStyle(
                  color: AppColors.smoke,
                  fontSize: 15.sp,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;

  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.smoke.withValues(alpha: 0.35),
                fontSize: 10.sp,
                height: 1.5,
                letterSpacing: 1.6,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

/// A compact row in "More episodes": thumbnail, meta line, title, subtitle.
class _MiniEpisodeRow extends StatelessWidget {
  final StudioEpisode episode;
  final VoidCallback onTap;

  const _MiniEpisodeRow({required this.episode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final meta = <String>[
      if (episode.number != null) l10n.studioEpisodeNumber('${episode.number}'),
      if ((episode.duration ?? '').isNotEmpty) episode.duration!,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 74.w,
              child: (episode.imageUrl ?? '').isEmpty
                  ? const ColoredBox(color: AppColors.mediumBackground)
                  : AppNetworkImage(
                      url: episode.imageUrl!,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        style: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 10.sp,
                          height: 1.5,
                        ),
                      ),
                    SizedBox(height: 3.h),
                    Text(
                      episode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 13.sp,
                        height: 1.35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((episode.subtitle ?? '').isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        episode.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
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
