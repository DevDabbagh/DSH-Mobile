/// Supabase connection details.
///
/// Read from `--dart-define` so the anon key never sits in the repository.
/// The defaults point at the shared DSH project, which is the same one the
/// website and dashboard use — the anon key is a public, RLS-gated key by
/// design, so shipping it in the binary is expected, but keeping it out of
/// version control still avoids it turning up in a public repo later.
///
/// Run with:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zqjoodsucaagrsnolooe.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_i-cbovx8nUrEOnNjFAaSnQ_P1Ie8Kq1',
  );

  /// The locale used when a field has no text in the user's language.
  /// Matches `isDefault` in the dashboard's `content_languages` setting.
  static const String defaultLocale = 'en';
}
