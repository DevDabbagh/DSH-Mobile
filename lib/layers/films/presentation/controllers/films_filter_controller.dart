import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/films/domain/entities/film.dart';

part 'films_filter_controller.g.dart';

/// What the reader has narrowed the films down to.
///
/// THE FACETS ARE THE WEBSITE'S
///
/// `FilmsListing.tsx` filters on exactly two things — `stage` and
/// `credits.form` — and this holds the same two, so a person who used the
/// site finds the same controls here. Adding a third facet is a decision to
/// make on both surfaces at once, not a thing to slip into one of them.
///
/// WHY THIS IS A PROVIDER AND NOT `setState` ON THE TAB
///
/// The Films tab and the full list are two screens showing one library.
/// Narrowing to fiction on the tab and then pressing "See all" has to arrive
/// at a list of fiction — arriving at everything, having just said what you
/// wanted, reads as the app forgetting. Shared state is the only way the two
/// screens can agree.
class FilmsFilter extends Equatable {
  /// Matched against title, logline and themes. Empty means no text filter —
  /// NOT "match nothing".
  final String query;

  final FilmStage? stage;
  final FilmForm? form;

  const FilmsFilter({
    this.query = '',
    this.stage,
    this.form,
  });

  /// How many facets are set. The search text is not counted: it is visible
  /// in the field, so the badge would be telling the reader something the
  /// screen already says.
  int get activeCount => (stage != null ? 1 : 0) + (form != null ? 1 : 0);

  bool get isActive => activeCount > 0 || query.trim().isNotEmpty;

  FilmsFilter copyWith({
    String? query,
    FilmStage? stage,
    bool clearStage = false,
    FilmForm? form,
    bool clearForm = false,
  }) =>
      FilmsFilter(
        query: query ?? this.query,
        stage: clearStage ? null : (stage ?? this.stage),
        form: clearForm ? null : (form ?? this.form),
      );

  /// Narrows a list. Pure, so both screens and the sheet's live result count
  /// can call it without any of them owning the answer.
  List<Film> apply(List<Film> all) {
    final q = query.trim().toLowerCase();

    return all.where((f) {
      if (stage != null && f.stage != stage) return false;
      if (form != null && f.credits.form != form) return false;
      if (q.isEmpty) return true;

      // Themes are searched too: "Palestine" is far more likely to be typed
      // than any of these titles, and it is a theme rather than a word in the
      // logline.
      return f.title.toLowerCase().contains(q) ||
          f.logline.toLowerCase().contains(q) ||
          f.themes.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  List<Object?> get props => [query, stage, form];
}

/// Deliberately NOT keepAlive.
///
/// The content lists are cached for the life of the app because refetching
/// them is expensive; a filter is the opposite — it is the reader's current
/// question, and it should not still be applied when they come back to Films
/// an hour later wondering where half the library went.
@riverpod
class FilmsFilterController extends _$FilmsFilterController {
  @override
  FilmsFilter build() => const FilmsFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setStage(FilmStage? value) => state = value == null
      ? state.copyWith(clearStage: true)
      : state.copyWith(stage: value);

  void setForm(FilmForm? value) => state = value == null
      ? state.copyWith(clearForm: true)
      : state.copyWith(form: value);

  /// Clears the text as well as the facets. "Clear all" that leaves a search
  /// term behind is the fastest way to believe the button is broken.
  void clear() => state = const FilmsFilter();
}
