import 'package:dsh_mobile/app/config/bunny_config.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/home/domain/entities/hero_slide.dart';

/// Maps the website's Header Slider config onto the app's slides.
///
/// This is a port of `buildHeroSlides()` in the website's `lib/landing.ts`,
/// deliberately rule for rule. The two surfaces read one row; if they read it
/// differently they are not sharing a slider, they are sharing a table.
///
/// The row's `config` is what the Landing Settings editor saves:
///
///   { "text": { … }, "slotIds": ["hero-1", …],
///     "slots": { "hero-1": { imageSrc, videoSrc, mediaType,
///                            cardType, cardTitle, ctaLink } } }
class HeroSlideModel {
  const HeroSlideModel._();

  static List<HeroSlide> fromConfigRow(Map<String, dynamic>? row) {
    if (row == null) return const [];

    // The whole slider can be switched off from Landing Settings. The site
    // honours that (`section.enabled === false` returns null) and so does
    // the app, rather than deciding for itself.
    if (row['enabled'] == false) return const [];

    final config = row['config'];
    if (config is! Map) return const [];

    final slots = config['slots'];
    if (slots is! Map) return const [];

    // `slotIds` carries the order. Reading `slots` directly would give
    // whatever order the JSON object happened to serialise in — which is not
    // an order at all, and would shuffle the carousel between builds.
    final ids = config['slotIds'];
    final ordered = ids is List
        ? ids.whereType<String>().toList()
        : slots.keys.whereType<String>().toList();

    final slides = <HeroSlide>[];

    for (final id in ordered) {
      final slot = slots[id];
      if (slot is! Map) continue;

      final isVideo = slot['mediaType'] == 'video';
      final image = resolveMediaUrl(slot['imageSrc']);

      // VIDEO IS A BUNNY ID NOW, NOT A URL
      //
      // The dashboard uploads to Bunny Stream and stores the video's id, so
      // the playable address is built here rather than read from the row —
      // which is what lets the CDN hostname change without rewriting every
      // slide. `videoProvider` says which form this slot holds; slides saved
      // before the move still carry a full URL and keep working.
      final rawVideo = slot['videoSrc']?.toString().trim() ?? '';
      final provider = slot['videoProvider']?.toString().trim() ?? '';

      final onBunny = provider == 'bunny' ||
          (provider.isEmpty && BunnyConfig.looksLikeId(rawVideo));

      final video = onBunny
          ? BunnyConfig.playbackUrl(rawVideo)
          : resolveMediaUrl(rawVideo);

      final media = isVideo ? video : image;

      // The site drops a slot with no media rather than rendering an empty
      // card. So does this.
      if (media.isEmpty) continue;

      slides.add(HeroSlide(
        id: id,
        isVideo: isVideo,
        mediaUrl: media,
        // For a video the still becomes the poster; for an image it is the
        // image itself, which is what the site does.
        // Bunny renders a still from the video itself. Preferred over an
        // empty poster because it is the exact frame playback begins on —
        // an editor who uploaded no poster still gets no flash of black.
        posterUrl: isVideo
            ? (image.isNotEmpty
                ? image
                : (onBunny ? BunnyConfig.thumbnailUrl(rawVideo) : ''))
            : media,
        cardType: slot['cardType']?.toString().trim() ?? '',
        cardTitle: slot['cardTitle']?.toString().trim() ?? '',
        ctaLink: slot['ctaLink']?.toString().trim() ?? '',
      ));
    }

    return slides;
  }
}
