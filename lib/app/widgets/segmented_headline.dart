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

  const SegmentedHeadline({
    super.key,
    required this.segments,
    this.style,
    this.textAlign = TextAlign.start,
    this.plainColor,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final base =
        (style ?? Theme.of(context).textTheme.displayLarge ?? const TextStyle())
            .copyWith(color: plainColor ?? AppColors.smoke);

    final direction = Directionality.of(context);

    // Nothing is highlighted — an ordinary paragraph, no measuring pass.
    if (!segments.any((s) => s.highlight)) {
      return Text(
        segments.map((s) => s.text).join(),
        style: base,
        textAlign: textAlign,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxes = _measure(base, constraints.maxWidth, direction);

        return Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < segments.length; i++)
                TextSpan(
                  text: segments[i].text,
                  style: segments[i].highlight
                      ? _gradientStyle(base, boxes[i], direction)
                      : null,
                ),
            ],
          ),
          style: base,
          textAlign: textAlign,
        );
      },
    );
  }

  /// Where each run lands once the paragraph is laid out.
  ///
  /// A run that wraps returns several boxes; they are unioned, so the gradient
  /// spans the whole phrase rather than restarting on the second line.
  List<Rect?> _measure(
    TextStyle base,
    double maxWidth,
    TextDirection direction,
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
    )..layout(maxWidth: maxWidth);

    final out = <Rect?>[];
    var offset = 0;

    for (final s in segments) {
      final start = offset;
      final end = offset + s.text.length;
      offset = end;

      if (!s.highlight) {
        out.add(null);
        continue;
      }

      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );

      out.add(boxes.isEmpty ? null : _union(boxes));
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

  /// The run painted with the brand gradient across [box].
  ///
  /// Falls back to a flat brand colour if the run could not be measured —
  /// better a solid pink word than an invisible one.
  TextStyle _gradientStyle(
    TextStyle base,
    Rect? box,
    TextDirection direction,
  ) {
    if (box == null || box.isEmpty) {
      return base.copyWith(color: AppColors.mainPurple);
    }

    // Setting `foreground` clears `color` for us — a TextStyle may carry one
    // or the other, never both.
    return base.copyWith(
      foreground: Paint()
        ..shader = AppColors.primaryGradient.createShader(
          box,
          // A directional gradient has no meaning without this, and in Arabic
          // it has to run from the other side.
          textDirection: direction,
        ),
    );
  }
}
