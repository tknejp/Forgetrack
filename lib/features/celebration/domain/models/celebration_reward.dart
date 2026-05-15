import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/domain/rarity.dart';

/// Resolves a localized string from the active [AppLocalizations].
typedef CelebrationText = String Function(AppLocalizations l10n);

/// Visual archetype of a reward. Drives the icon shown inside reward thumbs
/// and disc, completely independent of the reward's actual data source.
///
/// Adding a new kind: extend the enum, add the icon mapping in
/// `RewardThumb._iconForKind`, and adjust the secondary-CTA logic in
/// `CelebrationFullscreen` if the new kind should be considered "wearable".
enum CelebrationRewardKind {
  /// Generic XP / sparkle / unspecified — fallback for anything that doesn't
  /// fit the narrower kinds. Use sparingly.
  sparkle,

  /// Numeric XP reward (e.g. claimed quest XP). The amount is in the
  /// reward's [CelebrationReward.sub] line as a localized string.
  xp,

  /// Unlocked title (e.g. "Horský vyzyvatel").
  title,

  /// Achievement badge.
  badge,

  /// Streak / fire icon.
  flame,

  /// Quest / journey flag.
  flag,

  /// Map region / location.
  location,

  /// Cosmetic frame (avatar border).
  frame,

  /// Cosmetic background (profile scenery).
  background,

  /// Cosmetic companion / pet.
  companion,

  /// Generic gem / treasure.
  gem;

  /// Player-facing label describing this reward kind (e.g. "POZADÍ", "TITUL").
  /// Used by the fullscreen reward card's kind pill.
  String label(AppLocalizations l10n) {
    switch (this) {
      case CelebrationRewardKind.sparkle:
        return l10n.celebrationKindSparkle;
      case CelebrationRewardKind.xp:
        return l10n.celebrationKindXp;
      case CelebrationRewardKind.title:
        return l10n.celebrationKindTitle;
      case CelebrationRewardKind.badge:
        return l10n.celebrationKindBadge;
      case CelebrationRewardKind.flame:
        return l10n.celebrationKindFlame;
      case CelebrationRewardKind.flag:
        return l10n.celebrationKindFlag;
      case CelebrationRewardKind.location:
        return l10n.celebrationKindLocation;
      case CelebrationRewardKind.frame:
        return l10n.celebrationKindFrame;
      case CelebrationRewardKind.background:
        return l10n.celebrationKindBackground;
      case CelebrationRewardKind.companion:
        return l10n.celebrationKindCompanion;
      case CelebrationRewardKind.gem:
        return l10n.celebrationKindGem;
    }
  }
}

/// One reward inside a [CelebrationEvent]. Immutable; localized text is
/// resolved through closures so the same event can be re-rendered after a
/// language change without rebuilding the queue.
@immutable
class CelebrationReward {
  const CelebrationReward({
    required this.id,
    required this.name,
    required this.rarity,
    required this.kind,
    this.sub,
    this.assetPath,
    this.fallbackIcon,
  });

  /// Stable id within the celebration (e.g. cosmetic id, achievement id, or
  /// `xp:${rewardKey}` for a quest grant). Used as a Flutter widget key when
  /// listed.
  final String id;

  /// Player-facing reward name (e.g. "Rám horského vyzyvatele").
  final CelebrationText name;

  final Rarity rarity;
  final CelebrationRewardKind kind;

  /// Optional one-line subtitle below the name. Common uses: rarity label,
  /// "+205 XP", region name.
  final CelebrationText? sub;

  /// Optional preview asset (cosmetic art). When present and the loader
  /// succeeds, it replaces the fallback icon inside the disc / thumb.
  final String? assetPath;

  /// Override icon for kinds that don't have a default mapping or to
  /// distinguish two rewards of the same kind. Optional.
  final IconData? fallbackIcon;
}
