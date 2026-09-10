import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/search_scaffold.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_filter_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_list_card.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/films_filter_sheet.dart';

/// Searching the films — `/films/search`.
///
/// Declared OUTSIDE the shell, so it covers the tab bar. Searching wants the
/// keyboard and the whole height for results; a tab bar pinned to the bottom
/// would take the last row of the list and offer a way out of the thing the
/// reader just opened.
///
/// It reads and writes [FilmsFilterController] — the same state the tab and
/// `/films/all` use. Pressing search on the tab therefore arrives with
/// whatever was already narrowed still narrowed, and clearing a chip here is
/// visible when you come back.
class FilmsSearchPage extends ConsumerStatefulWidget {
  /// Opens the facet sheet as soon as the screen appears.
  ///
  /// The filter button on the Films tab sets this. Pressing filter there used
  /// to drop a sheet over the tab, so filtering and searching lived on two
  /// different screens with two different sets of chrome; now both buttons
  /// arrive here and the difference is only whether the sheet is already up.
  final bool openFilter;

  const FilmsSearchPage({super.key, this.openFilter = false});

  @override
  ConsumerState<FilmsSearchPage> createState() => _FilmsSearchPageState();
}

class _FilmsSearchPageState extends ConsumerState<FilmsSearchPage> {
  @override
  void initState() {
    super.initState();
    if (widget.openFilter) {
      // After the push transition, not during it — a modal route started
      // inside the same frame as the one pushing it animates from the wrong
      // place.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FilmsFilterSheet.open(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(filmsFilterControllerProvider);
    final ctl = ref.read(filmsFilterControllerProvider.notifier);
    final all = ref.watch(filmsListProvider).valueOrNull ?? const <Film>[];

    final matches = filter.apply(all);

    return SearchScaffold(
      title: l10n.filmsTab,
      hint: l10n.searchFilmsHint,
      initialQuery: filter.query,
      onSubmitted: ctl.setQuery,
      onFilterTap: () => FilmsFilterSheet.open(context),
      activeFilters: filter.activeCount,
      chips: [
        if (filter.form != null)
          SearchChip(
            label: filter.form == FilmForm.fiction
                ? l10n.filmFormFiction
                : l10n.filmFormDocumentary,
            onRemove: () => ctl.setForm(null),
          ),
        if (filter.stage != null)
          SearchChip(
            label: _stageLabel(l10n, filter.stage!),
            onRemove: () => ctl.setStage(null),
          ),
      ],
      body: _Results(filter: filter, matches: matches, onClear: ctl.clear),
    );
  }

  String _stageLabel(AppLocalizations l10n, FilmStage stage) {
    switch (stage) {
      case FilmStage.development:
        return l10n.filmStageDevelopment;
      case FilmStage.production:
        return l10n.filmStageProduction;
      case FilmStage.postProduction:
        return l10n.filmStagePostProduction;
      case FilmStage.festivals:
        return l10n.filmStageFestivals;
      case FilmStage.distribution:
        return l10n.filmStageDistribution;
      case FilmStage.impact:
        return l10n.filmStageImpact;
    }
  }
}

class _Results extends StatelessWidget {
  final FilmsFilter filter;
  final List<Film> matches;
  final VoidCallback onClear;

  const _Results({
    required this.filter,
    required this.matches,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = filter.query.trim();

    // Nothing typed yet shows the whole library rather than a message.
    //
    // The first version printed "type at least 3 letters" into the middle of
    // an otherwise empty screen, which is most of a phone showing nothing.
    // This screen is scoped to one section, so "everything in it" is a
    // perfectly good starting list — the reader can scroll it, filter it, or
    // start typing, and all three are visible from the first frame.
    //
    // The platform-wide `/search` does the opposite, and should: "everything"
    // there means three content types at once, which is not a list anyone
    // wants to be handed unasked.
    if (matches.isEmpty) {
      return SearchStatus(
        icon: Icons.search_off,
        message:
            query.isEmpty ? l10n.filterNoResults : l10n.searchNoResults(query),
        action: TextButton(
          onPressed: onClear,
          child: Text(
            l10n.filterClearFilters,
            style: TextStyle(color: AppColors.mainBlue, fontSize: 13.sp),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        6.h,
        AppDimensions.pagePadding.w,
        // No tab bar under this screen, so only the home indicator to clear.
        24.h,
      ),
      itemCount: matches.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, i) => FilmListCard(
        film: matches[i],
        onTap: () => context.push('/films/${matches[i].slug}'),
      ),
    );
  }
}
