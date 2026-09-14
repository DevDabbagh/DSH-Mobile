import 'package:flutter/material.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';

/// Text painted with a gradient instead of a flat colour.
///
/// Resolves the gradient against the ambient text direction, which a
/// directional gradient needs: `AlignmentDirectional.topStart` has no meaning
/// until something says which side "start" is on. Without it the brand
/// gradient would refuse to resolve, and in Arabic it would run the wrong way
/// across the words.
///
/// For a whole line of text, prefer [SegmentedHeadline] — it can colour a run
/// in the middle of a sentence, which this cannot. This is for the case where
/// every word is coloured.
class GradientText extends StatelessWidget {
  final String text;

  /// Defaults to the brand ramp, fitted to the width the text turns out to
  /// occupy. Pass one only to override it.
  final Gradient? gradient;

  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      // `bounds` is the painted size of the text, which is exactly the width
      // the ramp has to cross — so the blend is fitted here the same way
      // SegmentedHeadline fits it to a measured run. Without this a short
      // caption would show mostly the muddy middle of teal→pink, which is the
      // bug that sent "number." on the Impact hero back for a second look.
      shaderCallback: (bounds) =>
          (gradient ?? AppColors.brandRamp(bounds.width)).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        textDirection: Directionality.of(context),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
