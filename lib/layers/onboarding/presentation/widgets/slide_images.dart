import 'package:flutter/material.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';

/// The background imagery for one slide.
///
/// The number of images decides the treatment, and nothing else does: one
/// image fills the slide, several drift past each other as a mosaic — the
/// same rows-in-opposite-directions hero the Films and Studio tabs use.
///
/// There is deliberately no mode to pick. An editor uploads the photographs
/// they have; choosing between "single", "carousel" and "mosaic" was a
/// decision with only one sensible answer in each case, so the slide makes it.
class SlideImages extends StatelessWidget {
  final List<String> images;

  const SlideImages({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    // No image is a valid state: the slide falls back to the page background
    // and the copy still reads. Better than an error placeholder on a screen
    // that is the reader's first impression of the app.
    if (images.isEmpty) {
      return const ColoredBox(color: AppColors.background);
    }

    if (images.length == 1) {
      return _Single(url: images.first);
    }

    // LayoutBuilder because the mosaic needs a concrete height and this widget
    // is laid out by an expanded Stack, which gives it none.
    return LayoutBuilder(
      builder: (context, constraints) => DriftingMosaic(
        imageUrls: images,
        height: constraints.maxHeight,
        // Full strength and no scrim: OnboardingSlide already desaturates and
        // darkens the background and lays its own gradients over it, and
        // stacking both treatments turns the slide near-black.
        opacity: 1,
        scrim: false,
      ),
    );
  }
}

class _Single extends StatelessWidget {
  final String url;

  const _Single({required this.url});

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
