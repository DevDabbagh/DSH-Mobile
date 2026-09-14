import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/lang_helper.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/app/supabase/supabase_config.dart';
import 'package:dsh_mobile/app/supabase/supabase_provider.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_controller.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';

part 'section_header.g.dart';

/// Which inner page's header this is.
enum SectionHeaderKey {
  films('films_header'),
  studio('studio_header'),
  academy('academy_header');

  const SectionHeaderKey(this.settingsKey);

  final String settingsKey;
}

/// Where a section header's wall of photographs comes from.
///
/// Set in the dashboard, on each section's Header Settings tab (migration
/// 037). Before it existed the three headers each did their own thing: Films
/// built the wall from the real stills, Studio showed a Figma export, and
/// Academy showed *Studio's* export. The app, meanwhile, always built its own
/// from the covers — so the Studio header on a phone and the Studio header on
/// the site were two different walls.
enum HeaderImageMode {
  /// Imported from the catalogues named in [SectionHeader.sources].
  content,

  /// Images uploaded for this header specifically.
  tiles;

  // 'sheet' — one wide Figma export — was retired in migration 037. It could
  // only ever work on the website, and keeping it would have kept one
  // permanent difference between the two surfaces for the one section where
  // the mismatch was already the complaint. A row still holding it reads as
  // `content`, which is what the migration converts it to.
  static HeaderImageMode fromDb(String? value) =>
      value == 'tiles' ? HeaderImageMode.tiles : HeaderImageMode.content;
}

/// A catalogue a header wall can import posters from.
enum HeaderSource {
  films,
  studio,
  academy;

  static HeaderSource? fromDb(String? value) => switch (value) {
        'films' => HeaderSource.films,
        'studio' => HeaderSource.studio,
        'academy' => HeaderSource.academy,
        _ => null,
      };
}

/// Posters available to a header wall, by catalogue.
typedef HeaderImagePools = Map<HeaderSource, List<String>>;

/// The wall is three drifting rows. Below this the same photograph is visible
/// twice at once, which reads as a mistake rather than a pattern.
const int kMinHeaderTiles = 8;

/// A section header's settings, as the app needs them.
///
/// The images AND the copy. It used to be only the images: the headline came
/// from the app's own translations, so an editor who rewrote the Films
/// headline in the dashboard changed the website and not the phone, with
/// nothing anywhere to say why. Same row, same keys, same `pickLang` as
/// `readHeader()` on the website.
class SectionHeader {
  final HeaderImageMode mode;

  /// The headline, in three parts — the middle one carries the gradient.
  ///
  /// Split rather than one string because that is what the colouring needs:
  /// a single line with a shader over it would tint the plain half too.
  /// Films uses two parts, Studio and Academy three.
  final String titleNormal;
  final String titleColored;
  final String titleAfter;

  /// The standfirst under the headline. Empty means the screen keeps its own.
  final String description;

  /// Whether an editor has actually written a headline.
  ///
  /// Both halves empty is the untouched state, and the app then falls back to
  /// its translated default — which is also the only headline that exists in
  /// Arabic and Portuguese until someone writes one.
  bool get hasTitle => titleNormal.isNotEmpty || titleColored.isNotEmpty;

  /// Which catalogues [HeaderImageMode.content] imports from. A header is not
  /// limited to its own section: an Academy page with film posters behind it
  /// is a legitimate choice, and the editor makes it without a developer.
  final List<HeaderSource> sources;

  final List<String> tiles;

  const SectionHeader({
    this.mode = HeaderImageMode.content,
    this.sources = const [],
    this.tiles = const [],
    this.titleNormal = '',
    this.titleColored = '',
    this.titleAfter = '',
    this.description = '',
  });

  /// The wall to render.
  ///
  /// A port of `resolveHeaderTiles()` on the website, rule for rule — the two
  /// surfaces read one setting, and if they read it differently they are not
  /// sharing a header, they are sharing a row.
  ///
  /// Uploaded images below [kMinHeaderTiles] are topped up from every
  /// catalogue rather than left to repeat visibly. A short list is a warning
  /// in the editor, never a broken wall on a phone.
  List<String> resolve(HeaderImagePools pools) {
    if (mode == HeaderImageMode.tiles) {
      final chosen = tiles.where((t) => t.trim().isNotEmpty).toSet();
      if (chosen.length >= kMinHeaderTiles) return chosen.toList();

      // Everything, not just the selected sources — at this point the editor
      // has selected none, and a thin wall is the problem being solved.
      final everything = pools.values.expand((e) => e);
      return {...chosen, ...everything.where((u) => u.isNotEmpty)}.toList();
    }

    return {
      for (final source in sources) ...?pools[source],
    }.where((u) => u.isNotEmpty).toList();
  }
}

/// Reads one section's header settings.
///
/// keepAlive: three small rows that change when an editor saves, not while
/// someone is scrolling. Re-reading them on every visit to the tab would be a
/// query for a value that is almost always the same.
///
/// A failure returns the default rather than throwing — the header is
/// decoration around a listing, and a listing that refuses to render because
/// its wallpaper could not be read would be the wrong trade.
@Riverpod(keepAlive: true)
Future<SectionHeader> sectionHeader(Ref ref, SectionHeaderKey key) async {
  try {
    final row = await ref
        .read(supabaseClientProvider)
        .from('site_settings')
        .select('value')
        .eq('key', key.settingsKey)
        .maybeSingle();

    final value = row?['value'];
    if (value is! Map) return const SectionHeader();

    final rawTiles = value['tiles'];

    final rawSources = value['sources'];

    /* The text fields are JSONB keyed by language, exactly as the website
       reads them — `readHeader()` there runs the same four through
       `pickLang`. Resolved here so no screen can forget to. */
    final locale = ref.watch(localeControllerProvider).languageCode;
    String text(String field) =>
        pickLang(value[field], locale, SupabaseConfig.defaultLocale).trim();

    return SectionHeader(
      titleNormal: text('titleNormal'),
      titleColored: text('titleColored'),
      titleAfter: text('titleAfter'),
      description: text('description'),
      mode: HeaderImageMode.fromDb(value['imageMode']?.toString()),
      sources: rawSources is List
          ? rawSources
              .map((s) => HeaderSource.fromDb(s?.toString()))
              .whereType<HeaderSource>()
              .toList()
          : const [],
      tiles: rawTiles is List
          ? rawTiles
              .whereType<String>()
              .map(resolveMediaUrl)
              .where((u) => u.isNotEmpty)
              .toList()
          : const [],
    );
  } catch (_) {
    return const SectionHeader();
  }
}

/// Every catalogue a header wall may import posters from.
///
/// Reads the three content providers the app already keeps alive rather than
/// querying again — Films, Studio and Academy are all loaded by the time any
/// header renders, and a fourth round-trip for images that are already in
/// memory would be a query for nothing.
///
/// keepAlive so the three heroes share one map.
@Riverpod(keepAlive: true)
HeaderImagePools headerImagePools(Ref ref) {
  final films = ref.watch(filmsListProvider).valueOrNull ?? const [];
  final studio = ref.watch(studioListProvider).valueOrNull ?? const [];
  final academy = ref.watch(academyProgramsProvider).valueOrNull ?? const [];

  return {
    HeaderSource.films: films.map((f) => f.cardImageUrl).toList(),
    HeaderSource.studio: studio.map((p) => p.cardImageUrl).toList(),
    HeaderSource.academy: academy.map((p) => p.thumbnailUrl).toList(),
  };
}
