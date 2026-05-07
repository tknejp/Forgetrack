import 'package:flutter/material.dart';

import 'stat_card.dart';

enum DashboardCardKind {
  steps,
  nutrition,
  weight,
  sleep,
  activity,
}

class DashboardCardAssetResolver {
  const DashboardCardAssetResolver._();

  static StatCardVisualAssets forKind(DashboardCardKind kind) {
    final key = switch (kind) {
      DashboardCardKind.steps => 'steps',
      DashboardCardKind.nutrition => 'nutrition',
      DashboardCardKind.weight => 'weight',
      DashboardCardKind.sleep => 'sleep',
      DashboardCardKind.activity => 'activity',
    };

    return StatCardVisualAssets(
      iconAssetPath: 'assets/ui/dashboard/cards/${key}_icon.png',
      backgroundAssetPath: 'assets/ui/dashboard/cards/${key}_bg.png',
      backgroundAlignment: Alignment.centerRight,
      backgroundOpacity: _backgroundOpacity(kind),
    );
  }

  static double _backgroundOpacity(DashboardCardKind kind) {
    return switch (kind) {
      DashboardCardKind.steps => 0.30,
      DashboardCardKind.nutrition => 0.28,
      DashboardCardKind.weight => 0.30,
      DashboardCardKind.sleep => 0.30,
      DashboardCardKind.activity => 0.30,
    };
  }
}
