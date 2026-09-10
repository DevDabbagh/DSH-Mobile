import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/widgets/film_badges.dart';
import 'package:dsh_mobile/layers/home/domain/entities/home_section.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/colorize_on_scroll.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_chrome.dart';
import 'package:dsh_mobile/layers/impact/data/repositories/impact_repository_impl.dart';

/// The search field.
///
/// Still decorative — there is no search screen yet — so it is a tappable
/// affordance with a placeholder the dashboard writes, not a text field that
/// accepts input and then does nothing with it.
class HomeSearchBar extends StatefulWidget {
  final HomeSection section;

  const HomeSearchBar({super.key, required this.section});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  /// What the placeholder cycles through.
  ///
  /// Hardcoded, and it should not stay that way: everything else on this
  /// screen is written in the dashboard. There is no field for it on
  /// `page_sections` yet, so these live here until there is one — at which
  /// point they become `section.searchWords` and this list is the fallback.
  ///
  /// They are also English-only, which is the same debt in a second form.
  static const _words = ['Film', 'Course', 'Article', 'Event'];

  /// Typing is slower than deleting, the way a person types and then wipes a
  /// word out in one motion. The pause is what makes each word readable —
  /// without it the effect is a blur nobody can actually read.
  static const _typeStep = Duration(milliseconds: 110);
  static const _deleteStep = Duration(milliseconds: 55);
  static const _holdFull = Duration(milliseconds: 1100);

  Timer? _timer;
  int _word = 0;
  int _letters = 0;
  bool _deleting = false;

  /// The fixed half of the line.
  ///
  /// Deliberately NOT the dashboard's `placeholder`. That field holds the old
  /// full sentence — "Search films, episodes, courses…" — and using it as a
  /// prefix produced "Search films, episodes, courses Article…", which is the
  /// sentence and the animation fighting each other. The animated noun IS the
  /// list; there is nothing left for the sentence to say.
  ///
  /// English-only for now, like `_words`. Both belong in the dashboard once
  /// the section has a field for them.
  static const _prefix = 'Search';

  @override
  void initState() {
    super.initState();
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final word = _words[_word];

    Duration next;
    if (!_deleting && _letters < word.length) {
      _letters++;
      next = _letters == word.length ? _holdFull : _typeStep;
      if (_letters == word.length) _deleting = true;
    } else if (_deleting && _letters > 0) {
      _letters--;
      next = _deleteStep;
    } else {
      // Fully deleted — move to the next word and start typing again.
      _deleting = false;
      _word = (_word + 1) % _words.length;
      next = _typeStep;
    }

    // A one-shot timer rather than Timer.periodic: the interval changes with
    // the phase, and a periodic timer cannot pause on a finished word.
    _timer = Timer(next, () {
      if (!mounted) return;
      setState(_tick);
    });
  }

  @override
  Widget build(BuildContext context) {
    return homeSection(
      visible: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        // Not a real field. Tapping it opens `/search`, which has the actual
        // input and the keyboard — this is a button that looks like a field,
        // and the animated noun is what tells you it is worth pressing.
        //
        // The alternative, typing here, would need the results somewhere: the
        // Home screen is nine sections of curated content and there is nowhere
        // on it for a result list to go without shoving all nine down.
        child: GestureDetector(
          onTap: () => context.push('/search'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24.r),
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.05)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textMuted, size: 20.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Row(
                    children: [
                      // The verb stays put; only the noun is typed and wiped.
                      // Animating the whole string would make the line jitter
                      // sideways on every keystroke.
                      Text(
                        _prefix,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        ' ${_words[_word].substring(0, _letters)}…',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
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

/// The shortcut row.
///
/// Was five hardcoded tiles, one of which ("Support") had an empty `onTap`
/// and another of which routed to `/discover` under the label "Impact".
/// The tiles now come from the dashboard, and a tile with no route is
/// dropped by the model rather than rendered as a dead tap.
class HomeQuickActions extends StatelessWidget {
  final HomeSection section;

  const HomeQuickActions({super.key, required this.section});

  /// Names, not codepoints — the dashboard stores `"film"`, and a codepoint
  /// would tie an editor's dropdown to the Material font shipped in this
  /// build.
  static const _icons = <String, IconData>{
    'film': Icons.movie_outlined,
    'radio': Icons.podcasts_outlined,
    'school': Icons.school_outlined,
    'article': Icons.article_outlined,
    'calendar': Icons.calendar_today_outlined,
    'globe': Icons.public_outlined,
    'info': Icons.info_outline,
    'heart': Icons.favorite_outline,
    'premium': Icons.workspace_premium,
  };

  /// Shared with the CTA buttons, which draw from the same name set.
  /// Returns null for an empty or unrecognised name so the caller can leave
  /// the icon out entirely rather than drawing a placeholder circle.
  static IconData? iconFor(String name) => name.isEmpty ? null : _icons[name];

  @override
  Widget build(BuildContext context) {
    return homeSection(
      visible: section.actions.isNotEmpty,
      // Tight: the shortcuts read as a lead-in to the first rail rather than
      // a band floating between two sections.
      gap: kHomeTightGap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No heading. The row used to print `section.title` — the word
            // "Explore" — and the trouble was that the dashboard declares this
            // section `hasTitle: false`, so it never offers the field. The
            // value was left in the row from an earlier edit and there was no
            // way to remove it from the editor: a heading nobody could delete.
            //
            // Five labelled tiles do not need a word above them saying they
            // are things to explore. The renderer now agrees with the
            // dashboard about what this section has.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final action in section.actions)
                  Expanded(child: _ActionTile(action: action)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One shortcut.
///
/// Support is drawn in the brand pink rather than the same grey as the rest.
/// It is the one tile that asks for something instead of leading somewhere,
/// and the design marks it — the accent is the affordance.
///
/// Keyed on the route, not the label: the label is editable copy and may be
/// translated, so matching on "Support" would lose the accent the moment
/// someone writes "الدعم".
class _ActionTile extends StatelessWidget {
  final QuickAction action;

  const _ActionTile({required this.action});

  bool get _isSupport => action.route.startsWith('/support');

  @override
  Widget build(BuildContext context) {
    final tint = _isSupport ? AppColors.mainPurple : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => goToRoute(context, action.route),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: _isSupport
                  ? AppColors.mainPurple.withValues(alpha: 0.12)
                  : AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isSupport
                    ? AppColors.mainPurple.withValues(alpha: 0.55)
                    : AppColors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              HomeQuickActions.iconFor(action.icon) ?? Icons.circle_outlined,
              color: tint,
              size: 24.w,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tint,
              fontSize: 11.sp,
              fontWeight: _isSupport ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// One editorial pick, given the full width.
class HomeInFocus extends ConsumerWidget {
  final HomeSection section;

  const HomeInFocus({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final films = ref.watch(filmsListProvider).valueOrNull ?? const [];

    // Three steps down, most specific first: the film picked for this
    // section, then whichever is marked featured, then the newest.
    //
    // The pick wins over `isFeatured` on purpose — the flag belongs to the
    // film and shows up in several places, while this choice is about one
    // slot on one screen. An editor who sets it here means here.
    // `railItems` falls back to "the newest" when nothing is picked, which is
    // the right default for a rail and the wrong one here — it would step in
    // front of `isFeatured`. So the pick is only consulted when there is one.
    final picked = section.picks.isEmpty
        ? null
        : railItems(films, section.picks, 1, (f) => f.slug).firstOrNull;

    final film = picked ??
        films.where((f) => f.isFeatured).firstOrNull ??
        (films.isEmpty ? null : films.first);
    return homeSection(
      visible: film != null,
      child: film == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "View All" was missing entirely — the frame puts it at the
                // end of this row like every other section heading, and the
                // dashboard has always had the toggle for it.
                HomeSectionTitle(
                  title: section.title,
                  viewAllRoute: section.showViewAll
                      ? (section.viewAllRoute.isEmpty
                          ? '/films'
                          : section.viewAllRoute)
                      : '',
                ),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePadding.w,
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/films/${film.slug}'),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        // `cardSurface` (#131313), not `surface`.
                        //
                        // `AppColors.surface` is an alias for
                        // `mediumBackground` — #363636, a MID grey. Every
                        // other screen in the app builds its cards on
                        // `cardSurface`; Home was the last one still on the
                        // alias, which is why this card read as a pale slab
                        // laid on the page instead of the near-black panel the
                        // frame draws, barely separated from the background.
                        color: AppColors.cardSurface,
                        // 6 outside and 6 inside, the radius every other card
                        // on this screen uses. This one was 16 on the card and
                        // 12 on the poster — two radii nothing else shared,
                        // which made the single most prominent card on Home
                        // look like it came from a different app.
                        borderRadius: BorderRadius.circular(6.r),
                        // At #131313 on a #0D0D0D page the card would have no
                        // edge at all. The hairline is what gives it one —
                        // the same border Films, Studio and Support use.
                        border: Border.all(
                          color: AppColors.smoke.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [homeCardShadow()],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.r),
                              child: ColorizeOnScroll(
                                child: AppNetworkImage(
                                  url: film.posterUrl.isNotEmpty
                                      ? film.posterUrl
                                      : film.thumbnailUrl,
                                  width: 90.w,
                                  height: 120.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // "Documentary · 2026", as the frame writes
                                // it. It used to print the year alone, or a
                                // hardcoded "Youtube Series" when the year was
                                // missing — a label that was true of one film
                                // and printed over all of them.
                                Text(
                                  [
                                    FilmBadges.formLabel(l10n, film.credits),
                                    if (film.credits.year.isNotEmpty)
                                      film.credits.year,
                                  ].join(' · '),
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 9.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  film.title,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (film.credits.direction.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    film.credits.direction,
                                    style: TextStyle(
                                      color: AppColors.mainPurple,
                                      fontSize: 11.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                SizedBox(height: 8.h),
                                Text(
                                  film.logline.isNotEmpty
                                      ? film.logline
                                      : film.synopsisShort,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.sp,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    Text(
                                      l10n.homeReadMore,
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: AppColors.white,
                                      size: 12.w,
                                    ),
                                    const Spacer(),
                                    // The frame puts "3 min read" here.
                                    // Films have no reading time and never
                                    // will — this section reads `films`, not
                                    // articles — so the slot carries the
                                    // running time, which is the same kind of
                                    // fact and is a real column. Empty when
                                    // the film has none, rather than a zero.
                                    if (film.credits.duration.isNotEmpty)
                                      Text(
                                        film.credits.duration,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The impact figures — Figma `2170:1077`.
///
/// Previously three hardcoded numbers — "50+", "30+", "$500K" — over three
/// stock photographs. An invented impact figure is the single worst thing
/// this app could print, so this reads `impact_stats` and hides itself when
/// there is nothing to say.
///
/// WHY THE PHOTOGRAPHS ARE GONE
///
/// The frame is a centred heading over a plain row: an outline glyph, the
/// figure, the label. No imagery at all. The photo-card rail this used to
/// draw was a guess made before the frame was to hand, and it competed with
/// the two rails of poster art directly above it — three photographs of
/// people, then three more photographs of people with numbers on them.
///
/// `impact_stats.image_url` stays in the schema and is still used: the Impact
/// screen's own grid is built on it. It is this section that does not want it.
///
/// The icon comes from the row's `icon` column — the same eight names the
/// dropdown on /admin/impact offers.
class HomeImpact extends ConsumerWidget {
  final HomeSection section;

  const HomeImpact({super.key, required this.section});

  /// Names, not codepoints, matching `metricIconOptions` in the dashboard.
  /// An unknown name falls back to a neutral glyph rather than to nothing —
  /// the figure is the content here, and it must survive a typo in the icon.
  static const _icons = <String, IconData>{
    'Heart': Icons.favorite_border,
    'Users': Icons.people_outline,
    'Globe': Icons.public_outlined,
    'TrendingUp': Icons.trending_up,
    'MapPin': Icons.place_outlined,
    'Film': Icons.movie_outlined,
    'GraduationCap': Icons.school_outlined,
    'Play': Icons.play_circle_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Two sources, one row. `manual` is figures typed into this section;
    // `stats` — the default — is the shared `impact_stats` table, so the
    // numbers here, on the Impact screen and in the dashboard stay one set.
    //
    // The provider is watched either way. Reading it only in the `stats`
    // branch would change the set of providers this widget depends on
    // depending on a value inside a provider, and Riverpod resubscribes on
    // every build — the section would stop updating the first time an editor
    // switched to manual and back.
    final stats = ref.watch(impactStatsProvider).valueOrNull ?? const [];

    // Three across, as the frame draws it. A fourth would not fit the row on
    // a 360 dp phone without the labels wrapping into each other.
    final cap = section.limit.clamp(1, 3);

    final items = section.impactIsManual
        ? section.figures
            .take(cap)
            .map((f) => (display: f.display, label: f.label, icon: f.icon))
            .toList()
        : stats
            .take(cap)
            .map((s) => (display: s.display, label: s.label, icon: s.icon))
            .toList();

    return homeSection(
      visible: items.isNotEmpty,
      child: Column(
        children: [
          if (section.title.isNotEmpty) ...[
            Text(
              section.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding.w,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final stat in items)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          _icons[stat.icon] ?? Icons.insights_outlined,
                          color: AppColors.textMuted,
                          size: 22.w,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          stat.display,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24.sp,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          stat.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10.sp,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The closing call to action.
///
/// Was three buttons, none of which had an `onTap`. Headline, body and
/// buttons all come from the dashboard now, and a button with no route never
/// reaches this widget.
class HomeCta extends StatelessWidget {
  final HomeSection section;

  const HomeCta({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return homeSection(
      visible: section.buttons.isNotEmpty || section.title.isNotEmpty,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            // Same correction as In Focus above — see the note there.
            color: AppColors.cardSurface,
            // 6, like In Focus above it and the impact cards between them.
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: AppColors.smoke.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (section.title.isNotEmpty)
                Text(
                  section.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (section.body.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  section.body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ],
              if (section.buttons.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Row(
                  children: [
                    for (var i = 0; i < section.buttons.length; i++) ...[
                      if (i > 0) SizedBox(width: 8.w),
                      Expanded(child: _CtaButton(button: section.buttons[i])),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final HomeCtaButton button;

  const _CtaButton({required this.button});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => goToRoute(context, button.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: button.isPrimary ? AppColors.primaryGradient : null,
          // 6, like the card these sit in and every other card on the screen.
          // They were fully rounded pills at 24 — the only two on Home, which
          // made the closing card read as though it came from a different
          // design.
          border: button.isPrimary
              ? null
              : Border.all(color: AppColors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(6.r),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                button.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10.sp,
                  fontWeight:
                      button.isPrimary ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (HomeQuickActions.iconFor(button.icon) != null) ...[
              SizedBox(width: 4.w),
              Icon(
                HomeQuickActions.iconFor(button.icon),
                color: AppColors.white,
                size: 12.w,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
