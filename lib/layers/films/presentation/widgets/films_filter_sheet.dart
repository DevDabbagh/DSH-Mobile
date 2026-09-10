import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dsh_mobile/app/widgets/filter_sheet.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_filter_controller.dart';

/// The films half of the filter sheet: stage and form, the two facets the
/// website filters on.
///
/// A `ConsumerWidget` rather than a builder function, so the result count
/// under the button recounts as chips are tapped. Built as a plain widget the
/// number would be whatever it was when the sheet opened, and would sit there
/// contradicting the list behind it.
class FilmsFilterSheet extends ConsumerWidget {
  const FilmsFilterSheet({super.key});

  /// Opens it. Nothing to await — every choice applies as it is made.
  static Future<void> open(BuildContext context) => FilterSheet.show(
        context,
        builder: (_) => const FilmsFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(filmsFilterControllerProvider);
    final controller = ref.read(filmsFilterControllerProvider.notifier);
    final all = ref.watch(filmsListProvider).valueOrNull ?? const <Film>[];

    return FilterSheet(
      resultCount: filter.apply(all).length,
      hasActiveFilters: filter.isActive,
      onClearAll: controller.clear,
      groups: [
        // `FilterGroup.of<T>` rather than a generic FilterGroup: the enum has
        // to be resolved to labels and callbacks HERE, where the type is
        // known. See the comment on FilterGroup for what happened when it
        // wasn't.
        FilterGroup.of<FilmForm>(
          label: l10n.filterForm,
          values: FilmForm.values,
          labelOf: (f) => f == FilmForm.fiction
              ? l10n.filmFormFiction
              : l10n.filmFormDocumentary,
          selected: filter.form,
          onChanged: controller.setForm,
        ),
        FilterGroup.of<FilmStage>(
          label: l10n.filterStage,
          values: FilmStage.values,
          labelOf: (s) => _stageLabel(l10n, s),
          selected: filter.stage,
          onChanged: controller.setStage,
        ),
      ],
    );
  }

  /// Duplicated from `FilmBadges.stageLabel` rather than imported, because
  /// that one is a static on a widget class and pulling a whole badge widget
  /// into a filter sheet to reach a switch statement is the wrong dependency.
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
