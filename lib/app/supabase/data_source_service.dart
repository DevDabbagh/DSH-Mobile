import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'data_source_service.g.dart';

/// Content areas that can be switched between placeholder and real data from
/// the dashboard (Settings → Data Switcher).
enum ContentModule { films, studio, academy, articles, events, impact }

/// Reads the per-module `mock | live` switch the dashboard writes.
///
/// The website consults the same two `site_settings` rows in `lib/api.ts`;
/// without this the two surfaces disagree — a module set to "mock" would show
/// placeholder copy on the site while the app served whatever half-entered
/// rows happened to exist.
///
/// **The app never ships mock content.** Where the website falls back to its
/// bundled MOCK_FILMS, the app reports "not live" and the screen shows its
/// empty state. Realistic-looking placeholder films inside a store binary are
/// a different risk from placeholder films on a staging site.
class DataSourceService {
  final SupabaseClient _client;

  DataSourceService(this._client);

  /// Everything starts as mock, matching the website's DEFAULT_SOURCES: a
  /// module is live only once someone says so.
  static const _defaults = <ContentModule, String>{
    ContentModule.films: 'mock',
    ContentModule.studio: 'mock',
    ContentModule.academy: 'mock',
    ContentModule.articles: 'mock',
    ContentModule.events: 'mock',
    ContentModule.impact: 'mock',
  };

  Map<ContentModule, String>? _cached;
  DateTime? _cachedAt;

  /// Short enough that flipping the switch shows up almost immediately while
  /// browsing, long enough that a screen with several sections doesn't query
  /// settings once per section. Same 10s the website uses.
  static const _ttl = Duration(seconds: 10);

  Future<bool> isLive(ContentModule module) async {
    final sources = await _load();
    return sources[module] == 'live';
  }

  /// Drop the cache so the next read hits the database.
  ///
  /// Pull-to-refresh should mean "get me the current state", and without this
  /// a refresh inside the 10-second window would re-read a stale switch and
  /// look like the gesture did nothing.
  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  Future<Map<ContentModule, String>> _load() async {
    final now = DateTime.now();
    if (_cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _ttl) {
      return _cached!;
    }

    try {
      final rows = await _client
          .from('site_settings')
          .select('key, value')
          .inFilter('key', ['data_source_modules', 'data_source']);

      final list = List<Map<String, dynamic>>.from(rows);

      // Per-module settings win when present.
      final modulesRow = list.where((r) => r['key'] == 'data_source_modules');
      if (modulesRow.isNotEmpty) {
        final raw = _parseJsonb(modulesRow.first['value']);
        if (raw is Map) {
          final merged = Map<ContentModule, String>.from(_defaults);
          for (final m in ContentModule.values) {
            final v = raw[m.name];
            if (v == 'mock' || v == 'live') merged[m] = v as String;
          }
          return _cache(merged, now);
        }
      }

      // Legacy single switch for all modules, still honoured so an older
      // project that never wrote the per-module row keeps working.
      final globalRow = list.where((r) => r['key'] == 'data_source');
      if (globalRow.isNotEmpty) {
        final parsed = _parseJsonb(globalRow.first['value']);
        if (parsed == 'mock' || parsed == 'live') {
          return _cache(
            {for (final m in ContentModule.values) m: parsed as String},
            now,
          );
        }
      }
    } catch (_) {
      // Settings unreadable — fall through to the defaults rather than
      // assuming live and showing content that may not be ready.
    }

    return _cache(Map<ContentModule, String>.from(_defaults), now);
  }

  Map<ContentModule, String> _cache(Map<ContentModule, String> v, DateTime at) {
    _cached = v;
    _cachedAt = at;
    return v;
  }

  /// The column is JSONB, so a value may arrive already decoded or as a JSON
  /// string that still needs parsing — depends on how it was written.
  static dynamic _parseJsonb(dynamic value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
    return value;
  }
}

@Riverpod(keepAlive: true)
DataSourceService dataSourceService(Ref ref) =>
    DataSourceService(ref.read(supabaseClientProvider));
