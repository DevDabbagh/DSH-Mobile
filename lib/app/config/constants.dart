class Constants {
  Constants._();

  // API
  static const String baseUrl = 'https://api.dontskiphumanity.com/api/v1';
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // SharedPreferences Keys
  static const String userData = 'USER_DATA';
  static const String userAuthToken = 'AUTH_TOKEN';
  static const String userIsLogin = 'IS_LOGIN';
  static const String applicationLocale = 'APPLICATION_LOCALE';
  static const String hasSeenOnboarding = 'HAS_SEEN_ONBOARDING';
}
