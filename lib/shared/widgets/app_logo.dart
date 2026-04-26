import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../branding/app_branding.dart';

enum AppWordmarkVariant { auto, dark, light, gradient }

class AppLogoIcon extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const AppLogoIcon({
    super.key,
    this.size = 40,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        AppBranding.iconAsset,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class AppWordmark extends StatelessWidget {
  final double height;
  final AppWordmarkVariant variant;
  final BoxFit fit;
  final String? semanticsLabel;

  const AppWordmark({
    super.key,
    this.height = 24,
    this.variant = AppWordmarkVariant.auto,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _resolveAsset(context),
      height: height,
      fit: fit,
      semanticsLabel: semanticsLabel,
    );
  }

  String _resolveAsset(BuildContext context) {
    switch (variant) {
      case AppWordmarkVariant.auto:
        return AppBranding.wordmarkAssetForBrightness(
          Theme.of(context).brightness,
        );
      case AppWordmarkVariant.dark:
        return AppBranding.wordmarkDarkAsset;
      case AppWordmarkVariant.light:
        return AppBranding.wordmarkLightAsset;
      case AppWordmarkVariant.gradient:
        return AppBranding.wordmarkGradientAsset;
    }
  }
}

class AppBrandLockup extends StatelessWidget {
  final double iconSize;
  final double wordmarkHeight;
  final double gap;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final AppWordmarkVariant wordmarkVariant;

  const AppBrandLockup({
    super.key,
    this.iconSize = 32,
    this.wordmarkHeight = 18,
    this.gap = 10,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wordmarkVariant = AppWordmarkVariant.auto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        AppLogoIcon(size: iconSize),
        SizedBox(width: gap),
        Flexible(
          child: AppWordmark(
            height: wordmarkHeight,
            variant: wordmarkVariant,
          ),
        ),
      ],
    );
  }
}
