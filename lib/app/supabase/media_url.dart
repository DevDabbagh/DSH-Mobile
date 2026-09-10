/// Turning a stored image path into something the app can actually fetch.
///
/// Content rows hold two different kinds of value in the same column:
///
///   · `https://…supabase.co/storage/v1/object/public/media/…` — uploaded
///     through the dashboard, already absolute, works anywhere.
///   · `/images/studio.jpg` — site-relative, pointing at a file in the
///     website's `public/` folder. The browser resolves it against whatever
///     domain it is on; a phone has no such context and simply fails.
///
/// The second kind is why studio covers rendered as grey blocks: the URL was
/// never empty, it was just meaningless off the website. Resolving it here —
/// in the data layer, once — means every entity carries a URL that works, and
/// no screen has to know the difference.
library;

import 'package:dsh_mobile/app/config/site_config.dart';

/// An absolute, fetchable URL — or an empty string when there is nothing to
/// show, which every image widget already treats as "use the fallback".
String resolveMediaUrl(dynamic value) {
  if (value is! String) return '';

  final raw = value.trim();
  if (raw.isEmpty) return '';

  // Already absolute — including data: URIs, which some editors paste in.
  if (raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')) {
    return raw;
  }

  final path = raw.startsWith('/') ? raw : '/$raw';
  return '${SiteConfig.baseUrl}$path';
}

/// The same, for a list column.
List<String> resolveMediaUrls(Iterable<String> values) =>
    values.map(resolveMediaUrl).where((u) => u.isNotEmpty).toList();
