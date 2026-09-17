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

import 'package:dsh_mobile/app/config/bunny_config.dart';
import 'package:dsh_mobile/app/config/site_config.dart';

/// An absolute, fetchable URL — or an empty string when there is nothing to
/// show, which every image widget already treats as "use the fallback".
///
/// Supabase Storage URLs come back pointing at the Bunny image zone when one
/// is configured. This is the single place every entity's image passes
/// through on its way out of the data layer, which is what makes it the right
/// place to decide who delivers the bytes — see [BunnyConfig.imageUrl].
String resolveMediaUrl(dynamic value) {
  if (value is! String) return '';

  final raw = value.trim();
  if (raw.isEmpty) return '';

  // Already absolute — including data: URIs, which some editors paste in.
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return BunnyConfig.imageUrl(raw);
  }
  if (raw.startsWith('data:')) return raw;

  final path = raw.startsWith('/') ? raw : '/$raw';
  return '${SiteConfig.baseUrl}$path';
}

/// The same, for a list column.
List<String> resolveMediaUrls(Iterable<String> values) =>
    values.map(resolveMediaUrl).where((u) => u.isNotEmpty).toList();

/// The small copy of an uploaded image, or an empty string when there cannot
/// be one.
///
/// The dashboard writes `…/poster.webp` and `…/poster.thumb.webp` side by
/// side, so the second address is derivable from the first and no column had
/// to be added to a dozen tables to hold it.
///
/// WHY THIS MATTERS MORE THAN IT LOOKS
///
/// Stored images are up to 2000px on the long edge. The drifting mosaic draws
/// twelve tiles at about 130 logical pixels each — so it was pulling roughly
/// two hundred times the pixels it displays, twelve times over, on four
/// different screens. The thumbnail is ~600px and about a tenth of the bytes.
///
/// Returns empty for anything that is not a Supabase upload: a site-relative
/// asset, a data: URI, an SVG, a remote URL someone pasted. Callers treat
/// empty as "no thumbnail exists" and use the full image, which is also what
/// happens for everything uploaded before thumbnails existed.
String thumbMediaUrl(String fullUrl) {
  final url = fullUrl.trim();
  if (url.isEmpty) return '';

  // Two homes, not one.
  //
  // This used to test only for the Supabase Storage path, which was the only
  // place uploads went. Uploads go to Bunny Storage now, and a Bunny URL
  // carries no `/storage/v1/object/public/` — so this returned empty for every
  // newly uploaded image and the app quietly fell back to the full file.
  //
  // Nothing would have broken, which is the problem: the mosaic would have
  // gone back to pulling roughly ten times the bytes it displays, with no
  // error anywhere to say so.
  final isOurs = url.contains('/storage/v1/object/public/') ||
      url.contains('.b-cdn.net/') ||
      (BunnyConfig.imageCdnHost.isNotEmpty &&
          url.contains(BunnyConfig.imageCdnHost));

  if (!isOurs) return '';

  // Query strings would end up inside the filename.
  final cut = url.indexOf('?');
  final path = cut == -1 ? url : url.substring(0, cut);

  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf('/');
  if (dot <= slash) return ''; // no extension to replace

  // Already a thumbnail — asking for `x.thumb.thumb.webp` fetches nothing.
  if (path.endsWith('.thumb.webp')) return path;

  return '${path.substring(0, dot)}.thumb.webp';
}
