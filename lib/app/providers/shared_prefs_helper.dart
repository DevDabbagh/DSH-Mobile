import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dsh_mobile/app/config/constants.dart';

/// Wrapper around SharedPreferences for type-safe access.
class SharedPrefsHelper {
  final SharedPreferences _prefs;

  SharedPrefsHelper(this._prefs);

  // ── Auth Token ──
  String? getToken() => _prefs.getString(Constants.userAuthToken);

  Future<void> saveToken(String token) =>
      _prefs.setString(Constants.userAuthToken, token);

  Future<void> clearToken() => _prefs.remove(Constants.userAuthToken);

  // ── User Data ──
  Map<String, dynamic>? getUser() {
    final json = _prefs.getString(Constants.userData);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<void> saveUser(Map<String, dynamic> user) =>
      _prefs.setString(Constants.userData, jsonEncode(user));

  Future<void> clearUser() => _prefs.remove(Constants.userData);

  // ── Login State ──
  bool isLoggedIn() => _prefs.getBool(Constants.userIsLogin) ?? false;

  Future<void> setLoggedIn(bool value) =>
      _prefs.setBool(Constants.userIsLogin, value);

  // ── Onboarding ──
  bool hasSeenOnboarding() =>
      _prefs.getBool(Constants.hasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) =>
      _prefs.setBool(Constants.hasSeenOnboarding, value);

  // ── Locale ──

  /// The language the user picked, or null if they never has.
  ///
  /// Nullable on purpose: "no choice yet" and "chose English" are different
  /// states. Defaulting to 'en' here would show English to someone whose
  /// phone is in Portuguese before they ever open settings.
  String? getLocale() => _prefs.getString(Constants.applicationLocale);

  Future<void> setLocale(String locale) =>
      _prefs.setString(Constants.applicationLocale, locale);

  // ── Clear All ──
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
    await setLoggedIn(false);
  }
}
