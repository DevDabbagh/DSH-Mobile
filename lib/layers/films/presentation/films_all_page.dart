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
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_filter_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_list_card.dart';

/// The whole library — `/films/all`.
///
/// WHY IT IS A SCREEN AND NOT A LONGER TAB
///
/// The Films tab is a front page: a hero, the featured rail, and four films.
/// This is the catalogue. Separating them means the tab can stay short
/// however large the library gets, and this can be built for one job — find
/// a specific film — without a hero image between the reader and the list.
///
/// It shares [FilmsFilterController] with the tab rather than owning its own
/// state, so a search typed on the tab is still applied here. Two screens
/// over one library that disagree about what is being shown is the confusing
/// version of this.
///
/// Pushed, not switched to: this is not a tab, so `context.push` is right and
/// the Films tab stays selected in the bar underneath.
class FilmsAllPage extends ConsumerWidget {
  const FilmsAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filmsAsync = ref.watch(filmsListProvider);
    final filter = ref.watch(filmsFilterControllerProvider);
    final filterCtl = ref.read(filmsFilterControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: AppColors.deepBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 22.w),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/films'),
        ),
        title: Text(
          l10n.filmsAllTitle,
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
        // The same two icons as the tab, in the same place. An earlier draft
        // parked a full search field across the top of this screen; it worked
        // and it looked like a form, so search became a screen of its own and
        // this went back to being a list.
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.white, size: 20.w),
            onPressed: () => context.push('/films/search'),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color:
                  filter.activeCount > 0 ? AppColors.mainBlue : AppColors.white,
              size: 20.w,
            ),
            onPressed: () => context.push('/films/search?filter=1'),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: filmsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mediumGrey),
        ),
        error: (error, _) => ErrorRetryWidget(
          message: error is Failure ? error.message : l10n.filmsLoadError,
          onRetry: () => ref.read(filmsListProvider.notifier).refresh(),
        ),
        data: (films) {
          if (films.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.movie_outlined,
              title: l10n.filmsEmptyTitle,
              subtitle: l10n.filmsEmptyBody,
            );
          }

          final matches = filter.apply(films);

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
                            ref.read(filmsListProvider.notifier).refresh(),
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
                          itemBuilder: (context, i) => FilmListCard(
                            film: matches[i],
                            onTap: () =>
                                context.push('/films/${matches[i].slug}'),
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
