import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../progression_engine/domain/display/progression_display_models.dart';
import '../../progression_engine/domain/display/progression_display_resolver.dart';
import '../domain/social_models.dart';
import 'widgets/social_user_profile_sheet.dart';

const _resolver = ProgressionDisplayResolver();

// ── Level / domain helpers ────────────────────────────────────────────────────

Domain socialDomainFor(String? domain) =>
    (_resolver.parseDomain(domain) ?? ProgressionDomain.activity).token;

IconData socialIconFor(String? domain) =>
    _resolver.parseDomain(domain)?.icon ?? Icons.workspace_premium_rounded;

String socialRelativeTime(DateTime t, AppLocalizations l10n) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l10n.socialRelativeNow;
  if (d.inMinutes < 60) return l10n.socialRelativeMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.socialRelativeHoursAgo(d.inHours);
  if (d.inDays == 1) return l10n.socialRelativeYesterday;
  if (d.inDays < 7) return l10n.socialRelativeDaysAgo(d.inDays);
  return DateFormat('d. M.').format(t);
}

String socialFmtXp(int xp) {
  if (xp >= 100000) return '${(xp / 1000).round()}k';
  if (xp >= 10000) return '${(xp / 1000).toStringAsFixed(1)}k';
  return NumberFormat('#,##0').format(xp);
}

// ── Difficulty string bridge (cloud snapshots) ───────────────────────────────
//
// Friend achievement records are persisted in Firestore with the legacy
// `ProgressionAchievementDifficulty` enum *names* ("easy", "hard",
// "extraHard", …) baked into the snapshot. Until those records are
// migrated to use Rarity (Q5 decision: collapse Difficulty into Rarity),
// social keeps its own string-keyed colour and label maps so it does not
// have to import the legacy enum just to render a friend card.

const _difficultyColors = <String, Color>{
  'easy': Tokens.difficultyEasy,
  'medium': Tokens.difficultyMedium,
  'hard': Tokens.difficultyHard,
  'extraHard': Tokens.difficultyExtraHard,
  'mythic': Tokens.difficultyMythic,
};

Color colorForDifficultyString(String diff) =>
    _difficultyColors[diff] ?? Tokens.accent;

String socialDifficultyLabelForName(String diff, AppLocalizations l10n) {
  switch (diff) {
    case 'medium':
      return l10n.progAchievementDifficultyMedium;
    case 'hard':
      return l10n.progAchievementDifficultyHard;
    case 'extraHard':
      return l10n.progAchievementDifficultyExtraHard;
    case 'mythic':
      return l10n.progAchievementDifficultyMythic;
    case 'easy':
    default:
      return l10n.progAchievementDifficultyEasy;
  }
}

// ── Achievement → display mapping ────────────────────────────────────────────

/// Maps cloud-shaped friend achievement records into [NodeDisplay] payloads
/// for rendering. For each record:
///
/// - If the local catalog knows the id, returns the resolver's display
///   with the cloud `unlockedAt` carried over.
/// - Otherwise (renamed / removed / future-build id), builds a synthetic
///   display from the snapshot strings — friend cards stay informative
///   even when the local app does not know the achievement.
///
/// Sorted newest-unlocked-first; ties broken by node id for stability.
List<NodeDisplay> mapSocialAchievementsToDisplays(
  List<SocialUnlockedAchievement> achievements,
  AppLocalizations l10n,
) {
  final mapped = achievements.map((a) {
    final known = _resolver.nodeDisplay(a.achievementId, l10n);
    if (known != null) {
      return _withUnlockedAt(known, a.unlockedAt);
    }
    return _resolver.unknownNodeDisplay(
      nodeId: a.achievementId,
      fallbackTitle: a.title,
      fallbackDescription: a.description,
      accentColor: colorForDifficultyString(a.difficulty),
      domain: _resolver.parseDomain(a.domain),
      unlockedAt: a.unlockedAt,
    );
  }).toList();

  mapped.sort((a, b) {
    final unlockedCompare = (b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (unlockedCompare != 0) return unlockedCompare;
    return a.nodeId.compareTo(b.nodeId);
  });
  return mapped;
}

NodeDisplay _withUnlockedAt(NodeDisplay display, DateTime unlockedAt) {
  return NodeDisplay(
    nodeId: display.nodeId,
    kind: display.kind,
    title: display.title,
    description: display.description,
    rarity: display.rarity,
    accentColor: display.accentColor,
    badgeEmoji: display.badgeEmoji,
    assetKey: display.assetKey,
    unlockedAt: unlockedAt,
    domain: display.domain,
    targetValue: display.targetValue,
    currentValue: display.currentValue,
  );
}

// ── Achievement display helpers ──────────────────────────────────────────────

String friendAchievementDisplayLabel(
  NodeDisplay display,
  BuildContext context,
) =>
    _resolver.friendDisplayLabel(display, AppLocalizations.of(context));

String friendAchievementRarityLabel(
  NodeDisplay display,
  AppLocalizations l10n,
) =>
    display.rarity.label(l10n);

String friendAchievementCompactSummary(
  NodeDisplay display,
  AppLocalizations l10n,
  String locale,
) =>
    _resolver.compactSummary(display.nodeId, l10n, locale) ??
    display.title(l10n);

String formatAchievementDateTime(DateTime value, String locale) {
  return DateFormat('d MMM, HH:mm', locale).format(value);
}

// ── Navigation ────────────────────────────────────────────────────────────────

void openUserProfile(
  BuildContext context, {
  required String uid,
  String? initialDisplayName,
  String? initialPhotoUrl,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SocialUserProfileSheet(
      uid: uid,
      initialDisplayName: initialDisplayName,
      initialPhotoUrl: initialPhotoUrl,
    ),
  );
}
