import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/colorize_on_scroll.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_chrome.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';

/// The three content rails.
///
/// Each keeps the card it already had — Films is a poster grid, Studio is
/// wide cards, Academy is its own thing — and each now reads the published
/// rows instead of repeating one Unsplash photograph `itemCount` times.
///
/// A rail whose source has nothing published hides itself rather than
/// drawing a heading over an empty strip. That is not an error state: the
/// dashboard can legitimately be holding the module on `mock`.

class HomeFilmsRail extends ConsumerWidget {
  final HomeSection section;

  const HomeFilmsRail({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(filmsListProvider).valueOrNull ?? const [];
    final items = railItems(films, section.picks, section.limit, (f) => f.slug);

    return homeSection(
      visible: items.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: section.title,
            viewAllRoute: section.showViewAll ? section.viewAllRoute : '',
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 220.h,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, i) {
                final film = items[i];
                return GestureDetector(
                  onTap: () => context.push('/films/${film.slug}'),
                  child: Container(
                    width: 140.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [homeCardShadow()],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: ColorizeOnScroll(
                            child: AppNetworkImage(
                              url: film.posterUrl.isNotEmpty
                                  ? film.posterUrl
                                  : film.thumbnailUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.r),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.brandBlack.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: EdgeInsets.all(12.w),
                          alignment: AlignmentDirectional.bottomStart,
                          child: Text(
                            film.title,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeStudioRail extends ConsumerWidget {
  final HomeSection section;

  const HomeStudioRail({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(studioListProvider).valueOrNull ?? const [];
    final items =
        railItems(projects, section.picks, section.limit, (p) => p.slug);

    return homeSection(
      visible: items.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: section.title,
            viewAllRoute: section.showViewAll ? section.viewAllRoute : '',
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 140.h,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, i) => _StudioCard(project: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final StudioProject project;

  const _StudioCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // The chip used to alternate on `index % 2`, so the same project read
    // "In production" or "Pre-production" depending on where it happened to
    // land in the list — and neither string matched `StudioStatus`, which is
    // ongoing / complete / upcoming. It now says what the row actually says.
    final statusLabel = switch (project.status) {
      StudioStatus.ongoing => l10n.studioStatusOngoing,
      StudioStatus.complete => l10n.studioStatusComplete,
      StudioStatus.upcoming => l10n.studioStatusUpcoming,
    };

    final episodeCount = project.episodes.length;

    return GestureDetector(
      onTap: () => context.push('/studio/${project.slug}'),
      child: Container(
        width: 260.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: [homeCardShadow()],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: ColorizeOnScroll(
                  child: AppNetworkImage(
                    url: project.coverUrl.isNotEmpty
                        ? project.coverUrl
                        : project.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        AppColors.brandBlack.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (statusLabel.isNotEmpty)
              PositionedDirectional(
                start: 12.w,
                top: 12.h,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainPurple.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              start: 12.w,
              bottom: 12.h,
              end: 12.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    episodeCount > 0
                        ? l10n.studioEpisodeCount(episodeCount)
                        : project.oneLineDescription,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                    maxLines: 1,
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

class HomeAcademyRail extends ConsumerWidget {
  final HomeSection section;

  const HomeAcademyRail({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final programs = ref.watch(academyProgramsProvider).valueOrNull ?? const [];
    final items =
        railItems(programs, section.picks, section.limit, (p) => p.slug);

    return homeSection(
      visible: items.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.academySectionTag,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  section.title.isNotEmpty ? section.title : l10n.academyTitle,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.academySubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                // Was a Container styled as a button with no gesture on it.
                GestureDetector(
                  onTap: () => goToRoute(
                    context,
                    section.viewAllRoute.isNotEmpty
                        ? section.viewAllRoute
                        : '/academy',
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.browseCourses,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.white,
                          size: 14.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 180.h,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, i) => _AcademyCard(program: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyCard extends StatelessWidget {
  final AcademyProgram program;

  const _AcademyCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/academy/${program.slug}'),
      child: SizedBox(
        width: 140.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        boxShadow: [homeCardShadow()],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: AppNetworkImage(
                          url: program.thumbnailUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 8.w,
                    bottom: 8.h,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlack.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: AppColors.white,
                        size: 16.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              program.title,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              // The instructor, or the duration when nobody is credited —
              // the old version printed a fixed string here for every card.
              program.whoLeads.isNotEmpty ? program.whoLeads : program.duration,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
