import '../../application/progression_provider.dart';
import '../../domain/journey_models.dart';
import '../../domain/progression_models.dart';
import '../progression_l10n.dart';

/// Builds [JourneyCheckpoint] lists for both the Hero preview and the detail
/// map screen, plus a flat feed of milestone events for the detail screen feed.
///
/// TODO(journey): Replace with a full progression ledger
/// (`GET /journey/events?userId=…`) once the backend stores level-up,
/// title-unlock and streak-milestone timestamps. For now the adapter derives
/// what it can from the in-memory progression snapshot and synthesises past
/// level milestones (every 10 levels) without timestamps. Production UI must
/// not show fake or hard-coded sample events outside debug builds.
abstract final class JourneyAdapter {
  /// Compact 3–5 node list for the Hero preview card.
  static List<JourneyCheckpoint> buildPreview(
    ProgressionProvider provider,
    ProgressionL10n progL10n,
  ) {
    return buildFull(provider, progL10n)
        .take(5)
        .toList(growable: false);
  }

  /// Up to 14 nodes for the detail map (newest at top, oldest at bottom).
  /// First node may be a future locked level milestone.
  static List<JourneyCheckpoint> buildFull(
    ProgressionProvider provider,
    ProgressionL10n progL10n,
  ) {
    final profile = provider.profile;
    final list = <JourneyCheckpoint>[];

    // 1. Future locked next level milestone (every 5 levels).
    final nextMilestone = ((profile.level ~/ 5) + 1) * 5;
    if (nextMilestone > profile.level) {
      list.add(JourneyCheckpoint(
        id: 'level_future_$nextMilestone',
        type: JourneyEventType.level,
        label: 'Level $nextMilestone',
        sublabel: 'Další cíl',
        isUnlocked: false,
        levelNumber: nextMilestone,
      ));
    }

    // 2. Current level — always present, marked current.
    list.add(JourneyCheckpoint(
      id: 'level_current_${profile.level}',
      type: JourneyEventType.level,
      label: profile.levelTitle,
      sublabel: 'Level ${profile.level}',
      description: '${profile.totalXp} XP celkem',
      isUnlocked: true,
      isCurrent: true,
      levelNumber: profile.level,
    ));

    // 3. Recent unlocked achievements + completed quests, time-sorted desc.
    final dated = <_DatedCp>[];
    for (final a in provider.achievements) {
      if (a.unlocked && a.unlockedAt != null) {
        dated.add(_DatedCp(
          a.unlockedAt!,
          JourneyCheckpoint(
            id: 'ach_${a.id}',
            type: JourneyEventType.achievement,
            label: progL10n.achievementTitle(a),
            sublabel: 'Úspěch odemčen',
            description: progL10n.achievementDescription(a),
            unlockedAt: a.unlockedAt,
            isUnlocked: true,
          ),
        ));
      }
    }
    for (final q in provider.completedQuests) {
      if (q.completedAt != null) {
        dated.add(_DatedCp(
          q.completedAt!,
          JourneyCheckpoint(
            id: 'quest_${q.id}',
            type: JourneyEventType.quest,
            label: progL10n.questTitle(q),
            sublabel: 'Quest dokončen',
            description: progL10n.questDescription(q),
            unlockedAt: q.completedAt,
            isUnlocked: true,
          ),
        ));
      }
    }
    dated.sort((a, b) => b.at.compareTo(a.at));
    for (final d in dated.take(8)) {
      list.add(d.cp);
    }

    // 4. Best streak per domain (≥7 days). No reliable timestamp.
    for (final domain in ProgressionDomain.values) {
      final s = provider.streakForDomain(domain);
      if (s.bestStreak >= 7) {
        list.add(JourneyCheckpoint(
          id: 'streak_${domain.name}',
          type: JourneyEventType.streak,
          label: '${s.bestStreak} dní v řadě',
          sublabel: progL10n.domainLabel(domain),
          isUnlocked: true,
        ));
      }
    }

    // 5. Past level milestones (every 10 levels below current).
    // Synthetic — no timestamps available yet.
    for (int lvl = (profile.level ~/ 10) * 10; lvl > 0; lvl -= 10) {
      if (lvl >= profile.level) continue; // skip current's own milestone
      list.add(JourneyCheckpoint(
        id: 'level_past_$lvl',
        type: JourneyEventType.level,
        label: 'Level $lvl',
        sublabel: 'Milník dosažen',
        levelNumber: lvl,
        isUnlocked: true,
      ));
    }

    // 6. Journey start anchor — only if user is past level 1.
    if (profile.level > 1) {
      list.add(const JourneyCheckpoint(
        id: 'journey_start',
        type: JourneyEventType.level,
        label: 'Začátek cesty',
        sublabel: 'Level 1',
        levelNumber: 1,
        isUnlocked: true,
      ));
    }

    // Cap to keep the map readable. Preview takes its own subset off the top.
    return list.take(14).toList(growable: false);
  }

  /// Flat list of milestone events for the feed under the big map.
  /// Sorted by date desc. Includes only events with a known timestamp.
  static List<JourneyCheckpoint> buildFeed(
    ProgressionProvider provider,
    ProgressionL10n progL10n,
  ) {
    final dated = <_DatedCp>[];

    for (final a in provider.achievements) {
      if (a.unlocked && a.unlockedAt != null) {
        dated.add(_DatedCp(
          a.unlockedAt!,
          JourneyCheckpoint(
            id: 'feed_ach_${a.id}',
            type: JourneyEventType.achievement,
            label: progL10n.achievementTitle(a),
            sublabel: 'Úspěch odemčen',
            description: progL10n.achievementDescription(a),
            unlockedAt: a.unlockedAt,
            isUnlocked: true,
          ),
        ));
      }
    }

    for (final q in provider.completedQuests) {
      if (q.completedAt != null) {
        dated.add(_DatedCp(
          q.completedAt!,
          JourneyCheckpoint(
            id: 'feed_quest_${q.id}',
            type: JourneyEventType.quest,
            label: progL10n.questTitle(q),
            sublabel: 'Quest dokončen',
            description: progL10n.questDescription(q),
            unlockedAt: q.completedAt,
            isUnlocked: true,
          ),
        ));
      }
    }

    // TODO(journey): Add level-up and title-unlock events here once the
    // ledger persists their timestamps. Streak milestones likewise need
    // per-milestone dates — currently only `bestStreak` is exposed.

    dated.sort((a, b) => b.at.compareTo(a.at));
    return dated.map((d) => d.cp).toList(growable: false);
  }
}

class _DatedCp {
  const _DatedCp(this.at, this.cp);
  final DateTime at;
  final JourneyCheckpoint cp;
}
