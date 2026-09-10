/// The DSH website, as the app needs to address it.
///
/// The app talks to Supabase directly for content, but two things still live
/// on the website and cannot move:
///
///   · `/images/…` paths stored in content rows, which are relative to the
///     site and meaningless on a phone (see `media_url.dart`).
///   · `/api/stripe/checkout`, which holds the secret key. A donation has to
///     be started by the site; the app opens the returned Checkout URL.
///
/// Both resolve against this one value so that changing the domain is one
/// edit, not a search. Do not add a second base URL anywhere — that is exactly
/// how `Constants.baseUrl` came to point at a host that does not exist.
///
/// ⚠ TEMPORARY DEFAULT. `dont-skip-humanity.vercel.app` is the preview
/// deployment, not DSH's domain. When the real domain is connected this
/// default must change — see `DSH-Pre-Launch-Checklist.md`, item 1. Until then
/// a build can override it without a code change:
///
///   flutter build apk --dart-define=DSH_SITE_URL=https://dontskiphumanity.com
class SiteConfig {
  SiteConfig._();

  /// No trailing slash — every caller appends a path beginning with `/`.
  static String get baseUrl => _raw.replaceAll(RegExp(r'/+$'), '');

  static const String _raw = String.fromEnvironment(
    'DSH_SITE_URL',
    defaultValue: 'https://dont-skip-humanity.vercel.app',
  );

  /// True while the app is still pointed at the preview deployment. Lets a
  /// debug banner or a test assert catch a build that shipped unconfigured,
  /// rather than discovering it from a donor.
  static bool get isPreviewDomain => baseUrl.contains('vercel.app');

  /// Creates a Stripe Checkout session. POST — see the route for the body.
  static String get checkoutEndpoint => '$baseUrl/api/stripe/checkout';

  /// `{ "mode": "test" | "live" }` — whether real money moves.
  static String get stripeModeEndpoint => '$baseUrl/api/stripe/mode';

  /// Verifies a finished Checkout session AND records the donation. Calling it
  /// is not optional politeness — it is what files the gift when the webhook
  /// has not landed yet. GET, `?session_id=cs_…`.
  static String get sessionEndpoint => '$baseUrl/api/stripe/session';

  /// The donor's answer on the thank-you screen: their name, or anonymity.
  static String get claimEndpoint => '$baseUrl/api/donations/claim';
}
