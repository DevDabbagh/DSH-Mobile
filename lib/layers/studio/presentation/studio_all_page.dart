import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/app/widgets/list_preview.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_filter_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_project_card.dart';

/// The whole studio library — `/studio/all`.
///
/// The twin of `FilmsAllPage`, and the same reasoning: the tab is a front
/// page with a hero, a capability row and a featured project on it, so the
/// catalogue needs a screen of its own where nothing sits between the reader
/// and the list.
///
/// Shares [StudioFilterController] with the tab, so a format chosen there is
/// still chosen here.
class StudioAllPage extends ConsumerWidget {
  const StudioAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(studioListProvider);
    final filter = ref.watch(studioFilterControllerProvider);
    final filterCtl = ref.read(studioFilterControllerProvider.notifier);

    final cardWidth = MediaQuery.sizeOf(context).width - 40.w;

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: AppColors.deepBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 22.w),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/studio'),
        ),
        title: Text(
          l10n.studioAllTitle,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Start-aligned, not centred: in English the title sits left, and in
        // Arabic `false` puts it on the right by itself. `true` was pinning
        // it to the middle in every language.
        centerTitle: false,
        titleSpacing: 0,
        // The same two icons as the tab, in the same place.
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.white, size: 20.w),
            onPressed: () => context.push('/studio/search'),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color:
                  filter.activeCount > 0 ? AppColors.mainBlue : AppColors.white,
              size: 20.w,
            ),
            onPressed: () => context.push('/studio/search?filter=1'),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: error is Failure ? error.message : l10n.studioLoadError,
          onRetry: () => ref.read(studioListProvider.notifier).refresh(),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.podcasts_outlined,
              title: l10n.studioEmptyTitle,
              subtitle: l10n.studioEmptyBody,
            );
          }

          final matches = filter.apply(projects);

          return Column(
            children: [
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: NoFilterMatches(onClear: filterCtl.clear),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.mainBlue,
                        backgroundColor: AppColors.cardSurface,
                        onRefresh: () =>
                            ref.read(studioListProvider.notifier).refresh(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            AppDimensions.pagePadding.w,
                            12.h,
                            AppDimensions.pagePadding.w,
                            // No tab bar under this screen any more — it is
                            // declared outside the shell and covers it.
                            24.h,
                          ),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, i) => StudioProjectCard(
                            project: matches[i],
                            width: cardWidth,
                            onTap: () =>
                                context.push('/studio/${matches[i].slug}'),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
