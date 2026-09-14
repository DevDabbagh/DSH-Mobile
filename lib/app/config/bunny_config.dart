/// Where Bunny Stream videos are played from.
///
/// The app stores a Bunny video id, not a URL — see the dashboard's
/// `video-url.ts` for why. This turns the id into the playlist the player
/// opens.
///
/// WHY VIDEO IS ON BUNNY AT ALL
///
/// The home hero used to stream a 9.4MB MP4 out of Supabase Storage on loop,
/// uncached. Two days of development spent the project's whole monthly egress
/// allowance, and the arithmetic said roughly 530 visits to the Home screen
/// would do it again once real people arrived. Bunny transcodes to several
/// renditions, serves HLS so a weak connection drops quality rather than
/// stalling, and delivers from an edge near the viewer — which matters for an
/// audience in Brazil and the Middle East more than it does for us.
library;

class BunnyConfig {
  const BunnyConfig._();

  /// The pull-zone hostname, e.g. `vz-9b0a0795-bee.b-cdn.net`.
  ///
  /// Public by design — it appears in every playback URL the same way an
  /// image host does, so there is nothing here to protect. Overridable at
  /// build time so a staging library can be pointed at without a code change:
  ///
  ///   flutter build apk --dart-define=DSH_BUNNY_CDN=vz-other.b-cdn.net
  static const String cdnHost = String.fromEnvironment(
    'DSH_BUNNY_CDN',
    defaultValue: 'vz-9b0a0795-bee.b-cdn.net',
  );

  /// The IMAGE pull zone, e.g. `dsh-media.b-cdn.net`. Separate from
  /// [cdnHost], which is the Stream zone — Bunny treats video and files as
  /// different products, and they get different zones.
  ///
  /// This one is a plain CDN pull zone whose origin is the Supabase project
  /// URL. Bunny fetches each image from Supabase once and serves every later
  /// request from an edge, so those bytes stop counting against Supabase
  /// egress — the same reason video moved, applied to the thing the app
  /// actually downloads most of.
  ///
  /// Empty is the off switch: [resolveMediaUrl] then returns Supabase URLs
  /// untouched, exactly as before. Nothing stored depends on this value,
  /// because the swap happens when an image is read, never when it is saved.
  ///
  ///   flutter build apk --dart-define=DSH_IMAGE_CDN=dsh-media.b-cdn.net
  static const String imageCdnHost = String.fromEnvironment(
    'DSH_IMAGE_CDN',
    defaultValue: '',
  );

  /// The marker that says a URL is a file in Supabase Storage.
  static const String _storagePath = '/storage/v1/object/public/';

  /// [url] served through the image zone, or unchanged when there is no zone
  /// configured and for anything that is not a Supabase Storage URL.
  ///
  /// A site-relative asset, a `data:` URI and a link someone pasted to another
  /// site are all left alone: the first two have no host to swap, and the
  /// third belongs to somebody else and must not be proxied through our zone.
  static String imageUrl(String url) {
    if (imageCdnHost.isEmpty) return url;
    if (!url.contains(_storagePath)) return url;

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasAuthority) return url;

    // Already on a Bunny zone. Re-writing would be harmless, but being
    // explicit means this can be called twice without anyone checking.
    if (parsed.host.endsWith('.b-cdn.net')) return url;

    // Built rather than `.replace`d: `Uri.replace` reads a null argument as
    // "leave this part alone", so clearing a port through it is not the
    // obvious one-liner it looks like. Supabase URLs carry no port today, but
    // a rule that only works because of what the input happens to look like
    // is the kind that breaks quietly later.
    return Uri(
      scheme: 'https',
      host: imageCdnHost,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
    ).toString();
  }

  /// The adaptive playlist for [videoId], or empty if there is nothing to play.
  ///
  /// `video_player` handles HLS natively on both platforms — ExoPlayer on
  /// Android, AVPlayer on iOS — so no extra package is needed to read this.
  static String playbackUrl(String videoId) {
    final id = videoId.trim();
    if (id.isEmpty || cdnHost.isEmpty) return '';
    return 'https://$cdnHost/$id/playlist.m3u8';
  }

  /// The still Bunny generates from the video.
  ///
  /// Used as the hero poster when an editor has not uploaded one: it is the
  /// frame playback starts on, so there is no jump when the video begins.
  static String thumbnailUrl(String videoId) {
    final id = videoId.trim();
    if (id.isEmpty || cdnHost.isEmpty) return '';
    return 'https://$cdnHost/$id/thumbnail.jpg';
  }

  /// True when [value] has the shape of a Bunny id rather than a URL.
  ///
  /// Matched against a UUID specifically, not merely "not a URL". The loose
  /// version also matched a bare filename like `trailer.mp4` and would have
  /// built a playlist address out of it. This only runs for slides saved
  /// before `videoProvider` existed, so it should be exactly as narrow as the
  /// thing it is guessing at — anything it rejects is treated as a URL, which
  /// is what those older slides hold.
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool looksLikeId(String value) => _uuid.hasMatch(value.trim());
}
