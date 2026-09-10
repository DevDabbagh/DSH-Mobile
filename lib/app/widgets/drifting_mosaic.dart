import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

/// The hero backdrop on the Films and Studio tabs: rows of stills sliding
/// past each other, dimmed behind the headline.
///
/// This is the app's version of the website's `HeroMosaic`. Neighbouring rows
/// move in opposite directions — that counter-motion is what makes it read as
/// a living wall of film rather than a scrolling strip.
///
/// Purely decorative: it never blocks taps, and it renders nothing at all when
/// there are no images, so a section with no published content shows the
/// headline on a plain background instead of an empty grey grid.
class DriftingMosaic extends StatefulWidget {
  final List<String> imageUrls;

  /// Total height of the mosaic. Split evenly between [rowCount] rows.
  final double height;
  final int rowCount;

  /// Seconds for one row to travel its own width. Slow on purpose — fast
  /// enough to notice, slow enough to read the headline over.
  final double secondsPerCycle;

  /// How far the imagery is knocked back. The tab heroes dim it themselves;
  /// a caller that already darkens its background — onboarding does — passes
  /// 1.0 so the two treatments don't stack into near-black.
  final double opacity;

  /// The top/bottom fade into the page colour. Off for callers that lay their
  /// own scrim over the top, for the same reason.
  final bool scrim;

  /// Applies the website's tile treatment — see [_siteTint].
  ///
  /// Not just desaturation: grayscale, then the same brightness and contrast
  /// the site's Films listing puts on its hero mosaic, so the two surfaces
  /// show one wall rather than two gradings of it.
  ///
  /// Callers that turn this on should also pass `opacity: 1`. The tint
  /// already carries the darkening; the default 0.30 on top of it leaves
  /// roughly an eighth of the original light.
  final bool grayscale;

  const DriftingMosaic({
    super.key,
    required this.imageUrls,
    required this.height,
    this.rowCount = 3,
    this.secondsPerCycle = 60,
    this.opacity = 0.30,
    this.scrim = true,
    this.grayscale = false,
  });

  /// The website's tile treatment, as one matrix.
  ///
  /// `FilmsListing.tsx` passes its hero mosaic
  /// `grayscale(1) brightness(0.42) contrast(1.05)`. Three CSS filters
  /// compose left to right; a `ColorFilter.matrix` does the whole chain in
  /// one pass, which is what this is:
  ///
  ///   grey  = 0.2126·r + 0.7152·g + 0.0722·b   (luminance weights, not a
  ///           flat third each — a flat average turns reds muddy and greens
  ///           bright, the wrong way round for skin)
  ///   out   = ((grey × 0.42) − 0.5) × 1.05 + 0.5
  ///         =  grey × 0.441 − 0.025
  ///
  /// So each weight is scaled by 0.441, and the offset is −0.025 — expressed
  /// as −6.375 because the fifth column of a Flutter colour matrix is in
  /// 0–255, not 0–1. Getting that one conversion wrong is the difference
  /// between a slight lift and a black rectangle.
  ///
  /// Callers that use this pass `opacity: 1`: the 0.42 brightness IS the
  /// darkening, and stacking the old 0.30 opacity on top of it would leave
  /// roughly an eighth of the original light.
  static const ColorFilter _siteTint = ColorFilter.matrix(<double>[
    0.09376, 0.31540, 0.03184, 0, -6.375, //
    0.09376, 0.31540, 0.03184, 0, -6.375, //
    0.09376, 0.31540, 0.03184, 0, -6.375, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  State<DriftingMosaic> createState() => _DriftingMosaicState();
}

class _DriftingMosaicState extends State<DriftingMosaic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // One controller drives every row; each row reads it with its own offset
    // and direction. Three controllers would drift out of sync over time.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.secondsPerCycle.round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return SizedBox(height: widget.height);

    final rowHeight = widget.height / widget.rowCount;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      // Decorative only — taps belong to the buttons layered over it.
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: widget.opacity,
              // One filter over the whole wall rather than one per image:
              // ColorFiltered is a saveLayer, and thirty of them — three rows
              // of ten posters, each redrawn every frame — is thirty layers a
              // frame on a screen that never stops animating.
              child: _MaybeDesaturate(
                on: widget.grayscale,
                child: Column(
                  children: List.generate(widget.rowCount, (row) {
                    return _MosaicRow(
                      controller: _controller,
                      height: rowHeight,
                      // Odd rows travel the other way; this is the whole
                      // effect.
                      reverse: row.isOdd,
                      // Offsetting the start keeps the rows from lining up
                      // into visible vertical seams.
                      phase: row / widget.rowCount,
                      imageUrls: _rotated(widget.imageUrls, row),
                    );
                  }),
                ),
              ),
            ),
            // Fades the mosaic into the page: dark at the very top so the
            // header reads, clear through the middle, solid at the bottom so
            // the headline sits on flat colour.
            if (widget.scrim)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x660D0D0D),
                      Color(0x000D0D0D),
                      Color(0x000D0D0D),
                      Color(0xD90D0D0D),
                      AppColors.deepBackground,
                    ],
                    stops: [0.0, 0.30, 0.50, 0.75, 1.0],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Give each row a different starting image so the same poster isn't
  /// stacked three deep down the left edge.
  static List<String> _rotated(List<String> urls, int by) {
    if (urls.length < 2) return urls;
    final shift = by % urls.length;
    return [...urls.sublist(shift), ...urls.sublist(0, shift)];
  }
}

/// Wraps in a [ColorFiltered] only when asked. A `ColorFiltered` with an
/// identity matrix still costs a `saveLayer` every frame, so the colour
/// callers must not pay for the one that wants grey.
class _MaybeDesaturate extends StatelessWidget {
  final bool on;
  final Widget child;

  const _MaybeDesaturate({required this.on, required this.child});

  @override
  Widget build(BuildContext context) => on
      ? ColorFiltered(
          colorFilter: DriftingMosaic._siteTint,
          child: child,
        )
      : child;
}

class _MosaicRow extends StatelessWidget {
  final AnimationController controller;
  final double height;
  final bool reverse;
  final double phase;
  final List<String> imageUrls;

  const _MosaicRow({
    required this.controller,
    required this.height,
    required this.reverse,
    required this.phase,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final tileWidth = 110.w;
    const gap = 4.0;

    // Enough tiles to cover the screen twice: the row is drawn as two
    // identical halves, and translating by exactly one half's width makes the
    // loop seamless — the moment it resets, the pixels are the same.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tilesPerHalf = (screenWidth / (tileWidth + gap)).ceil() + 1;
    final halfWidth = tilesPerHalf * (tileWidth + gap);

    return SizedBox(
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = (controller.value + phase) % 1.0;
            // Forward rows slide 0 → -halfWidth; reversed rows run the same
            // span backwards, -halfWidth → 0, so they travel the other way.
            final dx = reverse ? (t - 1) * halfWidth : -t * halfWidth;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          // The row is deliberately twice the screen's width — that is what
          // makes the loop seamless. OverflowBox lifts the width constraint so
          // it can be, instead of being told it is 747 pixels too wide; the
          // ClipRect above still hides everything past the edge.
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: AlignmentDirectional.centerStart,
            // Pinned to LTR: this is decorative geometry, not text. Letting it
            // mirror in Arabic would flip which way each row drifts for no
            // reader-visible benefit, and the tile maths assumes one direction.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < tilesPerHalf * 2; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: gap),
                      child: SizedBox(
                        width: tileWidth,
                        height: height,
                        child: _Tile(url: imageUrls[i % imageUrls.length]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String url;

  const _Tile({required this.url});

  @override
  Widget build(BuildContext context) {
    // No shimmer here: this sits at 30% opacity behind a headline, so a
    // pulsing placeholder would be more distracting than a dark gap.
    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      // Behind a headline at 30% opacity a shimmer would be noise.
      shimmer: false,
    );
  }
}
