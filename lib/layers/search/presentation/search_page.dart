import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/widgets/search_scaffold.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_controller.dart';
import 'package:dsh_mobile/layers/films/domain/entities/film.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/impact/data/repositories/impact_repository_impl.dart';
import 'package:dsh_mobile/layers/impact/domain/entities/impact_story.dart';
import 'package:dsh_mobile/layers/search/presentation/controllers/recent_searches_controller.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';

/// Where the platform-wide search is looking.
///
/// Selecting none means "everywhere" — which is why this is a set of chosen
/// scopes rather than a set with all six pre-ticked. "I have not narrowed
/// this" and "I have ticked all six" are the same result and should not be
/// two different states.
enum SearchScope {
  films,
  studio,
  academy,
  read,
  impact,
  events;

  IconData get icon => switch (this) {
        SearchScope.films => Icons.movie_outlined,
        SearchScope.studio => Icons.podcasts_outlined,
        SearchScope.academy => Icons.school_outlined,
        SearchScope.read => Icons.menu_book_outlined,
        SearchScope.impact => Icons.public_outlined,
        SearchScope.events => Icons.calendar_today_outlined,
      };

  String label(AppLocalizations l10n) => switch (this) {
        SearchScope.films => l10n.filmsTab,
        SearchScope.studio => l10n.studioTab,
        SearchScope.academy => l10n.academy,
        SearchScope.read => l10n.browseRead,
        SearchScope.impact => l10n.browseImpact,
        SearchScope.events => l10n.browseEvents,
      };

  /// The section's colour, straight from the brand palette.
  ///
  /// Six sections, six identities — the same idea the website uses to keep
  /// them apart. A single white highlight for all six made the grid read as
  /// "three are on" and nothing else; the colour is what says *which* three.
  ///
  /// It carries through: the tile when it is chosen, the chip above the field,
  /// and the group heading over its results are all this one colour, so a
  /// section is recognisable in three places without reading a word.
  Color get accent => switch (this) {
        SearchScope.films => AppColors.mainBlue,
        SearchScope.studio => AppColors.mainPurple,
        SearchScope.academy => AppColors.successMain,
        SearchScope.read => AppColors.warningMain,
        SearchScope.impact => AppColors.blueLight2,
        SearchScope.events => AppColors.purpleLight1,
      };

  /// Where "browse this instead of searching it" goes.
  String get route => switch (this) {
        SearchScope.films => '/films',
        SearchScope.studio => '/studio',
        SearchScope.academy => '/academy',
        SearchScope.read => '/read',
        SearchScope.impact => '/discover',
        SearchScope.events => '/events',
      };

  /// Whether anything in this section can be searched yet.
  ///
  /// Read and Events have screens but no content layer — `articles` exists in
  /// the database (034) and the app has no repository for it, and Events is
  /// still a calendar with placeholder days. Saying so on the tile is better
  /// than letting someone tick it, type, and conclude the search is broken.
  bool get searchable => this != SearchScope.read && this != SearchScope.events;
}

/// Searching the whole platform — `/search`, from the Home screen's field.
///
/// Figma `2046:8631`.
///
/// WHY THIS IS A DIFFERENT SCREEN FROM `/films/search`
///
/// A section search has facets: stage and form on films, format and status on
/// studio. This one cannot — the facets do not exist across types, and a
/// "stage" filter that silently dropped every course would be worse than no
/// filter at all. So it trades facets for reach, and the Browse grid became
/// the way to aim it: tapping Films here does not open the Films tab, it says
/// "look in Films", which is what Ahmed asked for and what the tiles now do.
///
/// Results stay grouped by section rather than merged into one ranked list.
/// There is no score that means the same thing across a film, a podcast and a
/// course, so any single ordering would be invented. Grouping is the honest
/// version: three short lists under three headings, each one obviously
/// complete.
///
/// TRENDING IS NOT BUILT
///
/// The frame draws a row of trending searches. Nothing anywhere records what
/// is being searched for, so the only way to fill that row today is to type
/// four words into a Dart file and label them "trending" — a claim about other
/// people's behaviour that would be false the moment it shipped. Recent
/// searches are real and are here; trending waits until something counts.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// What was asked for. Carried to the results screen as `extra`.
class SearchRequest {
  final String query;
  final Set<SearchScope> scopes;

  const SearchRequest({required this.query, required this.scopes});
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _query = '';
  final Set<SearchScope> _scopes = {};

  /// Runs only when the keyboard's search key is pressed — never on the third
  /// keystroke.
  ///
  /// This screen is a form, not a live filter: the reader is choosing a query
  /// AND which sections to look in, and searching mid-sentence would throw
  /// them onto results before they had picked the sections. So it leaves for a
  /// results screen instead, and the picker stays underneath — coming back
  /// finds the query and the chosen sections exactly as they were, ready to be
  /// changed, rather than a blank field.
  void _submit(String value) {
    final query = value.trim();
    setState(() => _query = query);
    if (query.isEmpty) return;

    // Recorded on the way in, not on the way out: a reader who finds what they
    // wanted taps straight through to it and never returns here, and that is
    // precisely the search worth remembering.
    ref.read(recentSearchesProvider.notifier).record(query);

    context.push(
      '/search/results',
      extra: SearchRequest(query: query, scopes: {..._scopes}),
    );
  }

  void _toggle(SearchScope scope) {
    setState(() {
      _scopes.contains(scope) ? _scopes.remove(scope) : _scopes.add(scope);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchScaffold(
      title: l10n.searchTitle,
      hint: l10n.searchEverythingHint,
      initialQuery: _query,
      onSubmitted: _submit,
      searchAsYouType: false,
      // One chip per chosen section, each in that section's colour and each
      // with its own ×. Same row the section searches use for their facets —
      // here the "facet" is where to look.
      chips: [
        for (final scope in _scopes)
          SearchChip(
            label: scope.label(l10n),
            accent: scope.accent,
            onRemove: () => _toggle(scope),
          ),
      ],
      body: _Idle(
        scopes: _scopes,
        onToggleScope: _toggle,
        onPickRecent: _submit,
      ),
    );
  }
}

/// The results of one platform-wide search.
///
/// Separate from the picker so that going back is "change what I asked for"
/// rather than "start again". It repeats the query and the chosen sections at
/// the top for the same reason: by the time you have scrolled two groups down,
/// what you asked for is off the screen.
class SearchResultsPage extends StatelessWidget {
  final SearchRequest request;

  const SearchResultsPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: AppColors.deepBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 22.w),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/search'),
        ),
        title: Text(
          request.query,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          // Back to the picker, which is the screen underneath. Same gesture
          // as the arrow; here because "change the search" is the thing most
          // people want after reading a page of results, and the arrow does
          // not look like it means that.
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.white, size: 20.w),
            onPressed: () => context.pop(),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          if (request.scopes.isNotEmpty)
            SizedBox(
              height: 44.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding.w,
                  8.h,
                  AppDimensions.pagePadding.w,
                  0,
                ),
                itemCount: request.scopes.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, i) {
                  final scope = request.scopes.elementAt(i);
                  return _ScopeBadge(scope: scope, label: scope.label(l10n));
                },
              ),
            ),
          Expanded(
            child: _Results(query: request.query, scopes: request.scopes),
          ),
        ],
      ),
    );
  }
}

/// A read-only version of the chip: it says where this search looked. There is
/// no × because removing one here would mean re-running the search, and the
/// place to change the search is the screen behind this one.
class _ScopeBadge extends StatelessWidget {
  final SearchScope scope;
  final String label;

  const _ScopeBadge({required this.scope, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30.h,
      padding: EdgeInsets.symmetric(horizontal: 13.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scope.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scope.accent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scope.accent,
          fontSize: 12.sp,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/* ── nothing typed yet ──────────────────────────────────────────────── */

class _Idle extends ConsumerWidget {
  final Set<SearchScope> scopes;
  final ValueChanged<SearchScope> onToggleScope;
  final ValueChanged<String> onPickRecent;

  const _Idle({
    required this.scopes,
    required this.onToggleScope,
    required this.onPickRecent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recent = ref.watch(recentSearchesProvider).valueOrNull ?? const [];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        14.h,
        AppDimensions.pagePadding.w,
        24.h,
      ),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(l10n.searchRecent),
              GestureDetector(
                onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
                behavior: HitTestBehavior.opaque,
                child: Text(
                  l10n.searchClearRecent,
                  style: TextStyle(
                    color: AppColors.mainBlue,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          for (final term in recent)
            _RecentRow(
              term: term,
              onTap: () => onPickRecent(term),
              onRemove: () =>
                  ref.read(recentSearchesProvider.notifier).remove(term),
            ),
          SizedBox(height: 26.h),
        ],
        _Label(l10n.searchBrowse),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 1.9,
          children: [
            for (final scope in SearchScope.values)
              _BrowseTile(
                scope: scope,
                selected: scopes.contains(scope),
                onTap: () => onToggleScope(scope),
              ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.mediumGrey,
          fontSize: 10.sp,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _RecentRow extends StatelessWidget {
  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        child: Row(
          children: [
            Icon(Icons.history, color: AppColors.mediumGrey, size: 17.w),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                term,
                style: TextStyle(color: AppColors.smoke, fontSize: 14.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.close,
                  color: AppColors.mediumGrey,
                  size: 15.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile is a scope toggle, not a link.
///
/// It used to navigate — tapping "Films" left the search screen and opened the
/// Films tab, which meant the grid was a second tab bar sitting inside search.
/// Aiming the search is what someone on this screen actually wants; getting to
/// Films is what the tab bar underneath already does.
class _BrowseTile extends StatelessWidget {
  final SearchScope scope;
  final bool selected;
  final VoidCallback onTap;

  const _BrowseTile({
    required this.scope,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Unselected, every tile is identical — Read and Events included.
      //
      // They used to be dimmed to 45% because nothing in them is searchable
      // yet, and the result was two tiles that looked broken sitting beside
      // four that looked fine. Whether a section has been indexed is a fact
      // about this build, not about the section; it is said once, on the
      // results, rather than by greying out half the grid on arrival.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? scope.accent.withValues(alpha: 0.16)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: selected
                ? scope.accent
                : AppColors.smoke.withValues(alpha: 0.08),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              scope.icon,
              color: selected ? scope.accent : AppColors.lightGrey,
              size: 20.w,
            ),
            SizedBox(height: 8.h),
            Text(
              scope.label(l10n),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? scope.accent : AppColors.smoke,
                fontSize: 13.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

/* ── results ────────────────────────────────────────────────────────── */

/// One row of results, whatever it turned out to be.
class _Hit {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String route;

  const _Hit({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.route,
  });
}

class _Results extends ConsumerWidget {
  final String query;
  final Set<SearchScope> scopes;

  const _Results({required this.query, required this.scopes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final q = query.toLowerCase();

    // No scope chosen means every scope. See [SearchScope].
    bool wanted(SearchScope s) =>
        s.searchable && (scopes.isEmpty || scopes.contains(s));

    final films = ref.watch(filmsListProvider).valueOrNull ?? const <Film>[];
    final studio =
        ref.watch(studioListProvider).valueOrNull ?? const <StudioProject>[];
    final academy = ref.watch(academyProgramsProvider).valueOrNull ??
        const <AcademyProgram>[];
    final stories =
        ref.watch(impactStoriesProvider).valueOrNull ?? const <ImpactStory>[];

    final groups = <SearchScope, List<_Hit>>{
      if (wanted(SearchScope.films))
        SearchScope.films: [
          for (final f in films)
            if (f.title.toLowerCase().contains(q) ||
                f.logline.toLowerCase().contains(q) ||
                f.themes.any((t) => t.toLowerCase().contains(q)))
              _Hit(
                title: f.title,
                subtitle: f.logline,
                imageUrl: f.cardImageUrl,
                route: '/films/${f.slug}',
              ),
        ],
      if (wanted(SearchScope.studio))
        SearchScope.studio: [
          for (final p in studio)
            if (p.title.toLowerCase().contains(q) ||
                p.oneLineDescription.toLowerCase().contains(q))
              _Hit(
                title: p.title,
                subtitle: p.oneLineDescription,
                imageUrl: p.cardImageUrl,
                route: '/studio/${p.slug}',
              ),
        ],
      if (wanted(SearchScope.academy))
        SearchScope.academy: [
          for (final c in academy)
            if (c.title.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q))
              _Hit(
                title: c.title,
                subtitle: c.description,
                imageUrl: c.thumbnailUrl,
                // Academy has no detail route yet, so a course opens the tab
                // rather than a dead link.
                route: '/academy',
              ),
        ],
      if (wanted(SearchScope.impact))
        SearchScope.impact: [
          for (final s in stories)
            if (s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q))
              _Hit(
                title: s.title,
                subtitle: s.description,
                imageUrl: s.imageUrl,
                route: '/discover',
              ),
        ],
    }..removeWhere((_, hits) => hits.isEmpty);

    if (groups.isEmpty) {
      return SearchStatus(
        icon: Icons.search_off,
        message: l10n.searchNoResults(query),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        6.h,
        AppDimensions.pagePadding.w,
        24.h,
      ),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: EdgeInsets.only(top: 14.h, bottom: 10.h),
            child: Row(
              children: [
                // The section's own colour again — the third place it appears,
                // after the tile and the badge, so a group is identifiable
                // without reading its heading.
                Container(
                  width: 3.w,
                  height: 13.h,
                  decoration: BoxDecoration(
                    color: entry.key.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    entry.key.label(l10n).toUpperCase(),
                    style: TextStyle(
                      color: entry.key.accent,
                      fontSize: 10.sp,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${entry.value.length}',
                  style: TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (final hit in entry.value)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _HitCard(hit: hit),
            ),
        ],
      ],
    );
  }
}

class _HitCard extends StatelessWidget {
  final _Hit hit;

  const _HitCard({required this.hit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(hit.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: AppColors.smoke.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 76.w,
              height: 88.h,
              child: hit.imageUrl.isEmpty
                  ? const ColoredBox(color: AppColors.darkBackground)
                  : AppNetworkImage(url: hit.imageUrl, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hit.title,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hit.subtitle.isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Text(
                        hit.subtitle,
                        style: TextStyle(
                          color: AppColors.mediumGrey,
                          fontSize: 11.sp,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
