import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FigmaSvg extends StatelessWidget {
  const FigmaSvg(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.colorFilter,
    this.opacity = 1,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      colorFilter: colorFilter,
    );
    if (opacity >= 1) return svg;
    return Opacity(opacity: opacity, child: svg);
  }
}

class FigmaPng extends StatelessWidget {
  const FigmaPng(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clip = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
    );
    if (!clip) return image;
    return ClipRect(child: image);
  }
}
