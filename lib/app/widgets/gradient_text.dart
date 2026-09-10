import 'package:flutter/material.dart';

/// Text painted with a gradient instead of a flat colour.
///
/// Resolves the gradient against the ambient text direction, which a
/// directional gradient needs: `AlignmentDirectional.topStart` has no meaning
/// until something says which side "start" is on. Without it the brand
/// gradient would refuse to resolve, and in Arabic it would run the wrong way
/// across the words.
class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
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
