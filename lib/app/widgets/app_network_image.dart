import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';

/// Every remote image in the app, with one loading and one failure state.
///
/// The placeholder is a shimmer rather than a flat block, because a flat block
/// is indistinguishable from an image that has finished loading and happens to
/// be dark — which, on a screen this dark, is most of them. The shimmer says
/// "still coming" without needing a spinner.
///
/// Failure is quiet: a plain surface, no broken-image glyph. A missing still
/// on a film card is not something the reader can act on, and an error icon
/// would draw the eye to the one card that has least to show.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Turn the shimmer off where it would be noise rather than feedback —
  /// behind a headline at 30% opacity, for instance.
  final bool shimmer;

  /// Shown instead of the plain surface when there is no URL or the fetch
  /// fails. The profile avatar uses it to fall back to the person's initials,
  /// which says more than an empty circle does.
  final Widget? fallback;

  /// Fetch the ~600px copy instead of the full image.
  ///
  /// Set this anywhere the image is drawn small — mosaic tiles, cards, list
  /// rows, avatars. Leave it off for anything full-bleed.
  ///
  /// Safe to set on an image that has no thumbnail: the widget falls back to
  /// the full URL, which is what happens for every image uploaded before
  /// thumbnails existed and for anything that isn't a Supabase upload.
  final bool thumb;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.shimmer = true,
    this.fallback,
    this.thumb = false,
  });

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _fallback();

    final small = thumb ? thumbMediaUrl(url) : '';

    // No thumbnail is possible for this URL — go straight to the full image
    // rather than spending a failed request to find that out.
    if (small.isEmpty || small == url) return _image(url);

    return _image(
      small,
      // The thumbnail may simply not exist yet. A 404 here is expected, not
      // an error, so it falls through to the full image instead of the grey
      // placeholder. The cost of a missing thumbnail is one wasted request;
      // the cost of NOT doing this would be every pre-existing image on the
      // platform turning into a blank rectangle.
      onError: () => _image(url),
    );
  }

  Widget _image(String src, {Widget Function()? onError}) {
    return CachedNetworkImage(
      imageUrl: src,
      fit: fit,
      width: width,
      height: height,
      // Long enough to read as a fade rather than a flash, short enough not to
      // feel like the image is still arriving after it has.
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, _) => shimmer ? _shimmer() : _fallback(),
      errorWidget: (context, _, __) => onError?.call() ?? _fallback(),
    );
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardSurface,
      highlightColor: AppColors.mediumBackground,
      child: Container(
        width: width,
        height: height,
        color: AppColors.cardSurface,
      ),
    );
  }

  Widget _fallback() {
    return fallback ??
        Container(
          width: width,
          height: height,
          color: AppColors.mediumBackground,
        );
  }
}
