import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';

/// A headline built from runs, any of which can carry the brand gradient.
///
/// Replaces the older "plain text plus a coloured tail" shape, which could
/// only emphasise the END of a sentence. The onboarding frames colour words
/// in the middle too — "…that name **power** and refuse **erasure.**",
/// "**28** films. **15** countries." — so emphasis has to be able to land
/// anywhere.
///
/// **Each coloured run gets the whole gradient across its own box**: it starts
/// teal and ends pink, however short it is and wherever it sits in the
/// paragraph. One ramp stretched across the entire block was tried first and
/// was wrong — a word in the middle of the text landed on the midpoint of
/// teal→pink, which is a muddy grey, and the teal end never appeared on screen
/// at all.
///
/// Getting that right needs the runs measured before they are painted, since a
/// text shader is positioned in the paragraph's coordinate space, not the
/// run's. So this lays the headline out once invisibly, asks where each
/// coloured run ended up, and then paints it with a shader aligned to that
/// box.
class SegmentedHeadline extends StatelessWidget {
  final List<({String text, bool highlight})> segments;
  final TextStyle? style;
  final TextAlign textAlign;

  /// The colour of the runs that are not highlighted.
  final Color? plainColor;

  /// Shrink the type until the headline fits in this many lines.
  ///
  /// Null leaves it alone — the headline takes whatever height it needs, which
  /// is right for a page that scrolls. A hero cannot do that: it is a fixed
  /// box with a paragraph and two buttons under the headline, and a third line
  /// pushes them off the image.
  final int? maxLines;

  /// The floor for that shrinking. Below this the headline stops being a
  /// headline, so it is allowed to overflow instead — a clipped word is easier
  /// to recover from than one nobody can read.
  final double minFontSize;

  const SegmentedHeadline({
    super.key,
    required this.segments,
    this.style,
    this.textAlign = TextAlign.start,
    this.plainColor,
    this.maxLines,
    this.minFontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    // MEASURE WHAT WILL ACTUALLY BE PAINTED
    //
    // `Text` merges its style onto `DefaultTextStyle` — which is where the
    // app's font family comes from — and then scales it by the device's
    // accessibility text size. A `TextPainter` does neither unless told to.
    //
    // So the fitting pass below was measuring the platform's default font at
    // scale 1.0 while the screen drew the app's font at whatever scale the
    // phone is set to. It reported "fits in two lines", the real paragraph
    // needed three, and the headline came back ellipsised — the "…" that
    // auto-sizing exists to prevent. Resolving the style here, once, is what
    // makes every measurement below describe the widget that gets built.
    final resolved = DefaultTextStyle.of(context).style.merge(
          (style ??
                  Theme.of(context).textTheme.displayLarge ??
                  const TextStyle())
              .copyWith(color: plainColor ?? AppColors.smoke),
        );

    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    // Nothing is highlighted — an ordinary paragraph, no measuring pass.
    if (!segments.any((s) => s.highlight)) {
      return Text(
        segments.map((s) => s.text).join(),
        style: resolved,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = _fit(resolved, constraints.maxWidth, direction, scaler);
        final boxes = _measure(fitted, constraints.maxWidth, direction, scaler);

        return Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < segments.length; i++)
                TextSpan(
                  text: segments[i].text,
                  style: segments[i].highlight
                      ? _gradientStyle(fitted, boxes[i], direction)
                      : null,
                ),
            ],
          ),
          style: fitted,
          textAlign: textAlign,
          maxLines: maxLines,
          // Clipped, not ellipsised. [_fit] has already shrunk the type until
          // the whole headline fits, so an overflow here means it could not
          // fit even at [minFontSize] — and at that point a hard edge is
          // honest, where "…" reads as a headline someone truncated on
          // purpose.
          overflow: TextOverflow.clip,
        );
      },
    );
  }

  /// The largest size at or below the requested one that fits [maxLines].
  ///
  /// Stepped down half a point at a time rather than binary-searched: the
  /// range is a few dozen steps at most, each step is one `TextPainter.layout`
  /// on a single short paragraph, and this runs once per build of a headline —
  /// not per frame. Half-points because a whole one can be the difference
  /// between a headline that fits and one that loses its last word.
  TextStyle _fit(
    TextStyle base,
    double maxWidth,
    TextDirection direction,
    TextScaler scaler,
  ) {
    final requested = base.fontSize;
    if (maxLines == null || requested == null || maxWidth <= 0) return base;

    final text = segments.map((s) => s.text).join();

    for (var size = requested; size >= minFontSize; size -= 0.5) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: base.copyWith(fontSize: size)),
        textAlign: textAlign,
        textDirection: direction,
        textScaler: scaler,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);

      final overflows = painter.didExceedMaxLines;
      painter.dispose();

      if (!overflows) return base.copyWith(fontSize: size);
    }

    return base.copyWith(fontSize: minFontSize);
  }

  /// Where each run lands once the paragraph is laid out, and whether it
  /// wrapped onto a second line.
  ///
  /// The wrap flag is not a detail — see [_gradientStyle].
  ///
  /// Laid out under the SAME [maxLines] and scale as the widget. Without the
  /// line cap this painter was free to spill onto a third line, so a run that
  /// the screen draws entirely on line two was measured as wrapping — and got
  /// the vertical ramp meant for a genuine wrap, which is why the gradient
  /// came out starting mid-purple instead of at the teal end.
  List<({Rect? box, bool wrapped})> _measure(
    TextStyle base,
    double maxWidth,
    TextDirection direction,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        style: base,
        children: [
          for (final s in segments) TextSpan(text: s.text),
        ],
      ),
      textAlign: textAlign,
      textDirection: direction,
      textScaler: scaler,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);

    final out = <({Rect? box, bool wrapped})>[];
    var offset = 0;

    for (final s in segments) {
      final start = offset;
      final end = offset + s.text.length;
      offset = end;

      if (!s.highlight) {
        out.add((box: null, wrapped: false));
        continue;
      }

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );

      out.add((
        box: boxes.isEmpty ? null : _union(boxes),
        wrapped: _spansLines(boxes),
      ));
    }

    painter.dispose();
    return out;
  }

  static Rect _union(List<ui.TextBox> boxes) {
    var rect = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      rect = rect.expandToInclude(b.toRect());
    }
    return rect;
  }

  /// Whether the run's boxes sit on more than one line.
  ///
  /// Compared by top edge with a tolerance, because a run can produce several
  /// boxes on the SAME line — a bidi split, or a font fallback in the middle
  /// of a word — and those must not be mistaken for a wrap.
  static bool _spansLines(List<ui.TextBox> boxes) {
    if (boxes.length < 2) return false;
    final first = boxes.first.top;
    return boxes.any((b) => (b.top - first).abs() > 1);
  }

  /// The run painted with the brand gradient across [box].
  ///
  /// Falls back to a flat brand colour if the run could not be measured —
  /// better a solid pink word than an invisible one.
  ///
  /// WHY A WRAPPED RUN RUNS DOWN INSTEAD OF ACROSS
  ///
  /// A text shader maps colour to POSITION, and the run's box is the union of
  /// its per-line boxes. So on "…that stay close and **refuse erasure.**",
  /// where "refuse" ends line two and "erasure." begins line three, the union
  /// spans from x=45 (where "erasure." starts) to x=730 (where "refuse" ends).
  /// A left-to-right ramp then puts teal at x=45 — on "erasure." — and pink at
  /// x=730, on "refuse". The gradient came out backwards, in reading order,
  /// while being perfectly correct in screen order.
  ///
  /// Nothing about the horizontal ramp can fix that: the second line is
  /// physically to the LEFT of the first. So a wrapped run is given a vertical
  /// ramp instead — teal at the top line, pink at the bottom — which is the
  /// one axis that agrees with reading order on every line.
  TextStyle _gradientStyle(
    TextStyle base,
    ({Rect? box, bool wrapped}) run,
    TextDirection direction,
  ) {
    final box = run.box;
    if (box == null || box.isEmpty) {
      return base.copyWith(color: AppColors.mainPurple);
    }

    // Fitted to the axis the ramp actually crosses.
    final ramp = AppColors.brandRamp(run.wrapped ? box.height : box.width);

    final gradient = run.wrapped
        ? LinearGradient(
            colors: ramp.colors,
            stops: ramp.stops,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : ramp;

    // Setting `foreground` clears `color` for us — a TextStyle may carry one
    // or the other, never both.
    return base.copyWith(
      foreground: Paint()
        ..shader = gradient.createShader(
          box,
          // A directional gradient has no meaning without this, and in Arabic
          // it has to run from the other side.
          textDirection: direction,
        ),
    );
  }
}
