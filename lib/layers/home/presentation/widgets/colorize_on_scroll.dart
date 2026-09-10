import 'package:flutter/material.dart';

/// The website's signature move, on a phone: stills start black and white and
/// gain colour as the reader scrolls them up into view.
///
/// WHY IT STOPS AT 75% AND NOT 100%
///
/// Full saturation would make Home a wall of competing photographs — the
/// desaturation is what lets the screen read as one surface. Holding back a
/// quarter keeps the images subordinate to the type while still rewarding the
/// scroll. It is the same value the site uses.
///
/// WHY IT ONLY GOES ONE WAY
///
/// Colour ramps up as an image rises and then stays. The obvious
/// implementation — distance from the centre of the screen — also fades
/// images back to grey as they leave the top, so the rail you just looked at
/// drains behind you while you read the next one. That reads as a bug, not an
/// effect.
///
/// WHY THE FIRST FRAME IS GREY, DELIBERATELY
///
/// The size and position of a box are not known during the build that creates
/// it. Rather than guess, an unmeasured image renders fully desaturated — the
/// state it would have been in anyway, since anything below the fold starts
/// grey. It corrects on the next frame, which the scheduled rebuild forces.

/// Carries the Home scroll position down to every image, without every one of
/// them having to be handed a controller.
class HomeScrollScope extends InheritedNotifier<ScrollController> {
  const HomeScrollScope({
    super.key,
    required ScrollController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Null when used outside Home — the image then simply never colours,
  /// rather than throwing.
  static ScrollController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeScrollScope>()?.notifier;
}

/// How much of the way up the screen an image has to travel before it is
/// fully coloured. 0.55 puts the finish line just above the middle: an image
/// is at full colour by the time it is the thing you are looking at.
const double _travel = 0.55;

/// The ceiling. 1.0 would be the untouched photograph.
const double _maxSaturation = 0.75;

/// Home's stills are lifted slightly dark as well as desaturated, so they sit
/// under the type. The offset stays constant as colour comes in; only
/// saturation moves.
const double _lift = -20;

/// Rec. 709 luminance — the weights that decide what "grey" means for a
/// colour. Using the flat 1/3 each would make reds and blues the same shade.
const double _lr = 0.2126;
const double _lg = 0.7152;
const double _lb = 0.0722;

/// A saturation matrix: 0 is greyscale, 1 leaves the colour alone.
ColorFilter _saturate(double s) {
  final r = _lr * (1 - s);
  final g = _lg * (1 - s);
  final b = _lb * (1 - s);

  return ColorFilter.matrix(<double>[
    r + s, g, b, 0, _lift, //
    r, g + s, b, 0, _lift, //
    r, g, b + s, 0, _lift, //
    0, 0, 0, 1, 0, //
  ]);
}

class ColorizeOnScroll extends StatefulWidget {
  final Widget child;

  const ColorizeOnScroll({super.key, required this.child});

  @override
  State<ColorizeOnScroll> createState() => _ColorizeOnScrollState();
}

class _ColorizeOnScrollState extends State<ColorizeOnScroll> {
  double _saturation = 0;

  @override
  void initState() {
    super.initState();
    // First measurement, once this frame has been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final screen = MediaQuery.of(context).size.height;
    if (screen <= 0) return;

    final top = box.localToGlobal(Offset.zero).dy;

    // 0 while the image is still at or below the bottom edge; 1 once it has
    // climbed `_travel` of the screen height.
    final progress = ((screen - top) / (screen * _travel)).clamp(0.0, 1.0);
    final next = progress * _maxSaturation;

    // Only repaint on a visible change. Without this every pixel of scroll
    // rebuilds every image on screen for a difference nobody can see.
    if ((next - _saturation).abs() < 0.01) return;
    setState(() => _saturation = next);
  }

  @override
  Widget build(BuildContext context) {
    final controller = HomeScrollScope.maybeOf(context);

    if (controller == null) {
      return ColorFiltered(
        colorFilter: _saturate(_saturation),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Measured after this frame rather than during it: reading a position
        // mid-build gives the previous layout, which lags the finger by a
        // frame on a fast scroll.
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

        return ColorFiltered(
          colorFilter: _saturate(_saturation),
          child: child,
        );
      },
      // Passed as `child` so the image subtree is not rebuilt on every tick —
      // only the filter around it changes.
      child: widget.child,
    );
  }
}
