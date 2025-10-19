import 'package:flutter/material.dart';
import '../ui/theme.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color>? gradientColors;
  final TextOverflow? overflow;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradientColors,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
    ];

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: style,
        overflow: overflow ?? TextOverflow.clip,
        maxLines: 1,
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double fontSize;

  const AppLogo({super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lightning bolt icon with gradient
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.bolt,
            size: fontSize * 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        // Gradient text
        Flexible(
          fit: FlexFit.loose,
          child: GradientText(
            'CryptoBump',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
