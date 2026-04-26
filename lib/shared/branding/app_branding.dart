import 'package:flutter/material.dart';

class AppBranding {
  AppBranding._();

  static const String sourceIconAsset = 'assets/branding/app-icon.png';
  static const String iconAsset = sourceIconAsset;
  static const String iconSquareAsset = 'assets/branding/app-icon-square.png';
  static const String iconForegroundAsset =
      'assets/branding/app-icon-foreground.png';
  static const String wordmarkDarkAsset = 'assets/branding/wordmark-dark.svg';
  static const String wordmarkLightAsset = 'assets/branding/wordmark-light.svg';
  static const String wordmarkGradientAsset =
      'assets/branding/wordmark-gradient.svg';

  static String wordmarkAssetForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? wordmarkLightAsset
        : wordmarkDarkAsset;
  }
}
