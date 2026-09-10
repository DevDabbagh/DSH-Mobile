import 'package:equatable/equatable.dart';

/// One card in the header slider.
///
/// THE POINT OF THIS FILE
///
/// The website's Header Slider is edited in Landing Settings and stored in
/// `landing_page_config` under `section_key = 'hero'`. The app used to build
/// its own carousel from the newest published films instead — so the two
/// surfaces showed different things, and an editor who curated seven cards
/// for the site found the app ignoring every one of them.
///
/// They read the same rows now, through the same rules: this mirrors
/// `buildHeroSlides()` in the website's `lib/landing.ts` field for field. A
/// slide that the site drops, the app drops; a slide the site plays as
/// video, the app plays as video.
class HeroSlide extends Equatable {
  /// The slot key — "hero-1". Used to keep a video's controller tied to its
  /// own slide as the carousel recycles pages.
  final String id;

  /// Whether the card is a still or a film.
  final bool isVideo;

  /// The video for a video card, the image for a still one.
  final String mediaUrl;

  /// The still that sits under the video.
  ///
  /// For a video card this is the slot's `imageSrc`, exactly as on the site:
  /// the poster is *always* the base layer and the video plays on top of it,
  /// so a video that fails to load leaves the poster showing rather than a
  /// black rectangle.
  final String posterUrl;

  /// The editor's own label over the card — "Documentary", "Youtube Series".
  final String cardType;

  /// The headline. Written with line breaks in the editor, which the card
  /// design relies on, so it is passed through unchanged.
  final String cardTitle;

  /// Where the card goes, as the editor set it. Empty means the card is not
  /// a link — which is a real state on the site, not a missing value.
  final String ctaLink;

  const HeroSlide({
    required this.id,
    required this.mediaUrl,
    this.isVideo = false,
    this.posterUrl = '',
    this.cardType = '',
    this.cardTitle = '',
    this.ctaLink = '',
  });

  bool get hasLink => ctaLink.trim().isNotEmpty;

  @override
  List<Object?> get props =>
      [id, isVideo, mediaUrl, posterUrl, cardType, cardTitle, ctaLink];
}
