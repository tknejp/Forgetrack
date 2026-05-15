import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../progression_engine/domain/display/progression_display_models.dart';
import '../../progression_engine/domain/display/progression_display_resolver.dart';
import '../domain/social_models.dart';
import 'widgets/social_user_profile_screen.dart';

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

// ── Rarity → color / label ───────────────────────────────────────────────────
//
// Social snapshots store rarity directly (shared [Rarity] enum). Friend
// feed cards and unknown-id fallbacks both colour and label off the same
// source of truth as inventory cosmetics.

Color colorForRarity(Rarity rarity) => RarityPalette.forRarity(rarity).color;

String socialRarityLabel(Rarity rarity, AppLocalizations l10n) =>
    rarity.label(l10n);

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
      rarity: a.rarity,
      accentColor: colorForRarity(a.rarity),
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
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SocialUserProfileScreen(
        uid: uid,
        initialDisplayName: initialDisplayName,
        initialPhotoUrl: initialPhotoUrl,
      ),
    ),
  );
}
