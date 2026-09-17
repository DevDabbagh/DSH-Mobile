/// The backdrop behind every auth screen.
///
/// WHY THIS IS PAINTED AND NOT PHOTOGRAPHED
///
/// The obvious move was the drifting mosaic the Films, Studio, Impact and
/// onboarding screens already use — it is the app's signature and it would
/// have tied these screens to the rest. Two things argued against it here.
///
///   · Cost. The mosaic pulls a dozen stills. The project has just come off
///     an egress overage, and the sign-in screen is the one screen a person
///     may open before they have decided to trust us with anything.
///   · Legibility. Auth is four text fields and a keyboard. A wall of moving
///     photographs behind a form is the kind of thing that looks superb in a
///     screenshot and fights the user in the hand.
///
/// So the brand arrives as light instead of as imagery: DSH pink and DSH teal
/// bled through near-black, drifting slowly enough that you notice it only if
/// you stop to look. Zero bytes, no network, works on a plane, and it cannot
/// fail to load — which matters, because the alternative failure mode is a
/// grey rectangle on the first screen of the app.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';

class AuthBackdrop extends StatefulWidget {
  /// Stops the drift. Passed `true` while the keyboard is up: motion behind a
  /// form someone is typing into is noise, and holding still there costs
  /// nothing because nobody is looking at the background at that moment.
  final bool paused;

  const AuthBackdrop({super.key, this.paused = false});

  @override
  State<AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<AuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // Forty seconds for a full cycle. The glows travel a few percent of the
    // screen in that time, which is below the threshold where motion reads as
    // movement — it reads as the light being alive.
    duration: const Duration(seconds: 40),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.paused) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AuthBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused == oldWidget.paused) return;
    if (widget.paused) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Someone who has asked their phone to stop animating things has asked
    // for this too. They still get the gradient, just held still.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _controller.isAnimating) _controller.stop();

    // Its own layer, so the form above it is not repainted on every frame of
    // a forty-second drift.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BackdropPainter(still ? 0 : _controller.value),
          isComplex: true,
          willChange: !still && !widget.paused,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  /// 0 → 1 across one cycle.
  final double t;

  const _BackdropPainter(this.t);

  /// Not flat black. A hint of aubergine at the top and true near-black at
  /// the foot gives the screen a direction — it feels lit from above, which
  /// is what stops a dark UI from reading as a switched-off one.
  static const _base = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF17111A), Color(0xFF0C0B0F), Color(0xFF070709)],
    stops: [0.0, 0.58, 1.0],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = _base.createShader(rect));

    final a = t * 2 * math.pi;

    // Pink, upper trailing corner — the brand's loud colour, placed where the
    // logo sits so the mark has something to sit in rather than on.
    _glow(
      canvas,
      rect,
      center: Offset(
        size.width * (0.88 + 0.07 * math.sin(a)),
        size.height * (0.08 + 0.05 * math.cos(a)),
      ),
      radius: size.width * 1.15,
      color: AppColors.mainPurple,
      opacity: 0.34,
    );

    // Teal, lower leading corner. Counter-phase (0.8× and cosine-led) so the
    // two never drift in step — in step reads as one shape breathing, out of
    // step reads as two lights.
    _glow(
      canvas,
      rect,
      center: Offset(
        size.width * (0.04 + 0.06 * math.cos(a * 0.8)),
        size.height * (0.78 + 0.06 * math.sin(a * 0.8)),
      ),
      radius: size.width * 1.0,
      color: AppColors.mainBlue,
      opacity: 0.20,
    );

    // A wide, dim plum through the middle. Does almost nothing on its own;
    // what it does is stop the pink and the teal meeting as a grey seam
    // across the centre of the screen, which is exactly where the form is.
    _glow(
      canvas,
      rect,
      center: Offset(
        size.width * 0.46,
        size.height * (0.44 + 0.05 * math.sin(a * 0.5)),
      ),
      radius: size.width * 0.95,
      color: AppColors.purpleDark2,
      opacity: 0.26,
    );

    // Corners pulled down. Cinema does this to everything; here it also does
    // the practical work of keeping the glows off the edges of the screen,
    // where they would otherwise fight the status bar and the home indicator.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.58)],
          stops: const [0.45, 1.0],
        ).createShader(rect),
    );
  }

  /// One soft light. Drawn as a radial gradient rather than a blurred circle:
  /// a `MaskFilter` blur at this radius is a real cost on a mid-range Android
  /// phone, and a gradient with a squared falloff is indistinguishable from
  /// it at these opacities.
  void _glow(
    Canvas canvas,
    Rect bounds, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.45),
            color.withValues(alpha: 0),
          ],
          // Front-loaded stops: bright core, long tail. Evenly spaced stops
          // give a hard-edged disc, which is the difference between light and
          // a coloured blob.
          stops: const [0.0, 0.35, 1.0],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.t != t;
}
