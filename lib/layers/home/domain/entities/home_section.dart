import 'package:equatable/equatable.dart';

/// The sections the Home screen can render, in the order the dashboard
/// happens to put them.
///
/// Fixed, not free-form: the screen has a widget per kind and the design
/// assumes those shapes. A row whose `kind` this build does not recognise is
/// dropped rather than guessed at — an older app meeting a newer dashboard
/// should show one section fewer, not a crash.
enum HomeSectionKind {
  heroCarousel,
  search,
  quickActions,
  filmsRail,
  studioRail,
  academyRail,
  inFocus,
  impact,
  cta,
  unknown;

  static HomeSectionKind fromDb(String? value) {
    switch (value) {
      case 'hero_carousel':
        return HomeSectionKind.heroCarousel;
      case 'search':
        return HomeSectionKind.search;
      case 'quick_actions':
        return HomeSectionKind.quickActions;
      case 'films_rail':
        return HomeSectionKind.filmsRail;
      case 'studio_rail':
        return HomeSectionKind.studioRail;
      case 'academy_rail':
        return HomeSectionKind.academyRail;
      case 'in_focus':
        return HomeSectionKind.inFocus;
      case 'impact':
        return HomeSectionKind.impact;
      case 'cta':
        return HomeSectionKind.cta;
      default:
        return HomeSectionKind.unknown;
    }
  }
}

/// One tile in the shortcut row.
class QuickAction extends Equatable {
  /// A name from a fixed set the app maps to an icon — not an icon codepoint,
  /// which would tie the dashboard to a Flutter font.
  final String icon;
  final String label;
  final String route;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  List<Object?> get props => [icon, label, route];
}

/// One figure in the impact row, typed by hand in the dashboard.
///
/// Only used when the section's `source` is `manual`. On `stats` — the
/// default — the row reads `impact_stats` and this list is empty.
class HomeFigure extends Equatable {
  /// The number as typed. A String, not a num, so "4.2" and "500" both
  /// survive exactly as written — the figure is copy here, not arithmetic.
  final String value;

  /// "+", "K", "%" — appended to [value].
  final String suffix;

  final String label;

  /// A name from the same eight `impact_stats.icon` offers.
  final String icon;

  const HomeFigure({
    required this.value,
    required this.label,
    this.suffix = '',
    this.icon = '',
  });

  String get display => '$value$suffix';

  @override
  List<Object?> get props => [value, suffix, label, icon];
}

/// One button in the closing call to action.
class HomeCtaButton extends Equatable {
  final String label;
  final String route;

  /// 'primary' renders as the gradient button, anything else as bordered.
  final String style;

  /// Optional, from the same fixed name set [QuickAction] uses.
  final String icon;

  const HomeCtaButton({
    required this.label,
    required this.route,
    this.style = 'secondary',
    this.icon = '',
  });

  bool get isPrimary => style == 'primary';

  @override
  List<Object?> get props => [label, route, style, icon];
}

/// One section of the Home screen.
///
/// This is *layout*, not content. A rail says "show four films under this
/// heading"; the films themselves are read live from the films provider at
/// render time. Copying them in here would mean a film unpublished today
/// lingering on the Home screen until someone re-saved this row.
class HomeSection extends Equatable {
  final String id;
  final HomeSectionKind kind;
  final int position;

  /// Already resolved to the reader's language.
  final String title;

  /// How many items a rail shows when nothing has been picked.
  final int limit;

  /// The slugs an editor chose for this rail, in the order they chose them.
  ///
  /// **Slugs, not copies.** This is the whole design: the rail still reads
  /// live rows from `films` / `studio_items` / `academy_programs` and uses
  /// this only to filter and order them. So a film that is unpublished
  /// tomorrow leaves the Home screen on its own, exactly as it does now —
  /// where copying the card in here would have left it on display until
  /// someone thought to come back and remove it.
  ///
  /// Empty means "not curated": the rail falls back to the newest [limit],
  /// which is what every rail did before picking existed.
  final List<String> picks;

  final bool showViewAll;
  final String viewAllRoute;

  /// hero_carousel only — seconds between slides.
  final int autoplaySeconds;

  /// search only.
  final String placeholder;

  /// quick_actions only.
  final List<QuickAction> actions;

  /// cta only.
  final String body;
  final List<HomeCtaButton> buttons;

  /// impact only — where the figures come from.
  ///
  /// `stats` reads `impact_stats`, so the numbers on Home, on the Impact
  /// screen and in the dashboard are one set with one place to change them.
  /// `manual` uses [figures], typed into this section.
  ///
  /// Both exist because they answer different questions. `stats` is right
  /// when the figures are DSH's real running totals; `manual` is right when
  /// Home wants to say something a table cannot hold — a rounded headline
  /// number, or a figure that is not counted anywhere yet.
  ///
  /// Defaults to `stats`: an editor who has never opened this setting should
  /// get the shared numbers, not an empty section.
  final String impactSource;

  /// impact + `manual` only.
  final List<HomeFigure> figures;

  const HomeSection({
    required this.id,
    required this.kind,
    required this.position,
    this.title = '',
    this.limit = 4,
    this.picks = const [],
    this.showViewAll = false,
    this.viewAllRoute = '',
    this.autoplaySeconds = 5,
    this.placeholder = '',
    this.actions = const [],
    this.body = '',
    this.buttons = const [],
    this.impactSource = 'stats',
    this.figures = const [],
  });

  bool get impactIsManual => impactSource == 'manual';

  @override
  List<Object?> get props =>
      [id, kind, position, title, limit, picks, impactSource, figures];
}
