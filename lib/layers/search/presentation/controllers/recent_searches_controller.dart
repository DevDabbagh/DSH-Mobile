// `AsyncValue` comes from here, not from riverpod_annotation. Without this
// import the generator cannot resolve the notifier's state type and silently
// writes no .g.dart at all — which surfaces as "no such file", several steps
// away from the actual mistake.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'recent_searches_controller.g.dart';

/// The last few things this person searched for.
///
/// WHY IT IS ON THE DEVICE AND NOT IN SUPABASE
///
/// Most of the app browses as a guest, so there is frequently no account to
/// attach a search history to. Storing it server-side would mean either
/// losing it for exactly the people most likely to be looking for something,
/// or building an anonymous-identity table to hold a list of words — which is
/// a lot of machinery, and a lot of retained personal data, for a convenience.
///
/// It also means a search history never leaves the phone. That is the right
/// default for a platform whose readers include people searching for
/// "Palestine" and "Gaza journalism".
const _key = 'dsh.recent_searches';

/// Enough to be useful, short enough that the list never needs its own
/// scroll. The design draws four.
const int kMaxRecentSearches = 6;

@Riverpod(keepAlive: true)
class RecentSearches extends _$RecentSearches {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  /// Newest first, no duplicates, capped.
  ///
  /// Re-searching an old term moves it to the top rather than adding a second
  /// copy — a history with the same word four times is a history of one
  /// search.
  Future<void> record(String term) async {
    final value = term.trim();
    // The three-character minimum is the search field's, not this one's: a
    // term short enough not to have run is not a search that happened.
    if (value.length < 3) return;

    final current = state.valueOrNull ?? const <String>[];
    final next = [
      value,
      ...current.where((t) => t.toLowerCase() != value.toLowerCase()),
    ].take(kMaxRecentSearches).toList();

    state = AsyncValue.data(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  Future<void> remove(String term) async {
    final current = state.valueOrNull ?? const <String>[];
    final next = current.where((t) => t != term).toList();

    state = AsyncValue.data(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  Future<void> clear() async {
    // Typed explicitly: `const AsyncValue.data([])` infers
    // `AsyncValue<List<dynamic>>`, which then fails to assign to state.
    state = AsyncValue.data(const <String>[]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
