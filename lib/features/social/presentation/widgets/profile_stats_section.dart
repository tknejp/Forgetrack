import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import 'package:forgetrack/domain/progression/catalog/progression_domain.dart';

import '../../../../app/player_provider.dart';
import '../../../cosmetics/application/cosmetics_provider.dart';
import '../../../health_connect/application/fitness_provider.dart';
import '../../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../../../progression_engine/application/progression_engine_provider.dart';
import '../../application/social_provider.dart';
import '../../domain/profile_stat_catalog.dart';
import '../../domain/social_user_profile.dart';
import 'hero_streak_stats_card.dart';
import 'profile_stat_card.dart';

/// Top-level "STATISTIKY" section rendered under the streak-records
/// card on the profile screen.
///
/// Owns the edit-mode UX for the owner's stat visibility blacklist:
///   * Header pencil → flips section into edit mode (eye toggles on
///     every row, value cells hidden).
///   * Header "Hotovo" / "Zrušit" → commits pending blacklist via
///     [SocialProvider.setCurrentHiddenStatKeys] or discards it.
///
/// Foreign-profile viewers see a strictly read-only section with
/// rows filtered through [isStatVisibleForViewer]. Cards whose every
/// row is hidden render no header — instead of leaking how many
/// rows the owner has hidden, the whole card disappears.
class ProfileStatsSection extends StatefulWidget {
  const ProfileStatsSection({
    super.key,
    required this.profile,
    required this.isMe,
    this.friendCount,
    this.sharedPostsCount,
  });

  /// The user whose profile is being viewed. May be the signed-in
  /// user (own profile) or a friend / arbitrary user.
  final SocialUserProfile? profile;

  /// True when the viewer is the owner of [profile]. Drives:
  ///   * Whether owner-only stats are rendered at all.
  ///   * Whether the header pencil + edit-mode chrome appears.
  ///   * Whether hidden rows render muted (owner) or skip (foreign).
  final bool isMe;

  /// Friend count for the [social.friendsCount] row. Pass null while
  /// the friends stream is still loading — the cell will render `—`.
  final int? friendCount;

  /// Shared posts count for the [social.sharedPostsCount] row. Null
  /// renders `—`. Pulled from the same stream the shared-posts list
  /// below the stats already subscribes to, so reusing the count is
  /// free.
  final int? sharedPostsCount;

  @override
  State<ProfileStatsSection> createState() => _ProfileStatsSectionState();
}

class _ProfileStatsSectionState extends State<ProfileStatsSection> {
  bool _editing = false;
  late Set<String> _pendingOverrides;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pendingOverrides = Set<String>.from(
      widget.profile?.statVisibilityOverrides ?? const <String>{},
    );
  }

  @override
  void didUpdateWidget(covariant ProfileStatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the upstream profile stream emits a fresh snapshot AND we
    // are not in the middle of editing, sync the pending set so the
    // section reflects the latest persisted override set (e.g.
    // toggled from another device).
    if (!_editing) {
      _pendingOverrides = Set<String>.from(
        widget.profile?.statVisibilityOverrides ?? const <String>{},
      );
    }
  }

  Set<String> get _effectiveOverrides => _editing
      ? _pendingOverrides
      : (widget.profile?.statVisibilityOverrides ?? const {});

  /// Toggles the user's choice for [key]. Under XOR semantics this is
  /// a single set toggle regardless of the catalog default — adding
  /// the key flips visibility against the default, removing it
  /// restores the default.
  void _toggleVisibility(String key) {
    setState(() {
      if (_pendingOverrides.contains(key)) {
        _pendingOverrides.remove(key);
      } else {
        _pendingOverrides.add(key);
      }
    });
  }

  Future<void> _commit() async {
    setState(() => _saving = true);
    final social = context.read<SocialProvider>();
    await social.setCurrentStatVisibilityOverrides(_pendingOverrides);
    if (!mounted) return;
    setState(() {
      _editing = false;
      _saving = false;
    });
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _pendingOverrides = Set<String>.from(
        widget.profile?.statVisibilityOverrides ?? const <String>{},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = <Widget>[];
    final visibilityResolver = _VisibilityResolver(
      overrides: _effectiveOverrides,
      isOwner: widget.isMe,
      editing: _editing,
    );

    // For the owner the canonical join date lives on the Player
    // aggregate (`engine.joinedAt`, persisted across ledger wipes via
    // SharedPreferences). Foreign profiles only carry the Firestore-
    // mirrored `createdAt` on the wire, so we fall back to it. The
    // Player.anonymous sentinel uses epoch 0 — guard against it so a
    // pre-bind frame doesn't render "1.1.1970".
    final joinedAt = _resolveJoinedAt(context);

    final heroCard = _buildHeroCard(context, l10n, visibilityResolver, joinedAt);
    if (heroCard != null) cards.add(heroCard);

    final streakCard = _buildStreakCard(context, visibilityResolver);
    if (streakCard != null) cards.add(streakCard);

    final activity = _buildActivityCard(context, l10n, visibilityResolver);
    if (activity != null) cards.add(activity);
    final sleep = _buildSleepCard(context, l10n, visibilityResolver);
    if (sleep != null) cards.add(sleep);
    final body = _buildBodyCard(context, l10n, visibilityResolver);
    if (body != null) cards.add(body);
    final nutrition =
        _buildNutritionCard(context, l10n, visibilityResolver);
    if (nutrition != null) cards.add(nutrition);

    final social = _buildSocialCard(context, l10n, visibilityResolver, joinedAt);
    if (social != null) cards.add(social);

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsHeader(
          l10n: l10n,
          isOwner: widget.isMe,
          editing: _editing,
          saving: _saving,
          onEdit: () => setState(() => _editing = true),
          onSave: _commit,
          onCancel: _cancel,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          cards[i],
        ],
      ],
    );
  }

  // ── Card builders ─────────────────────────────────────────────────

  /// Resolves the "join date" the stats section should show:
  ///   * Own profile → `PlayerProvider.player.joinedAt` (canonical,
  ///     anchors retroactive claim windows; persisted across ledger
  ///     wipes). Falls through to `createdAt` if the Player is still
  ///     the [Player.anonymous] sentinel (epoch 0) — happens for the
  ///     pre-bind frame.
  ///   * Foreign profile → `SocialUserProfile.createdAt` (the only
  ///     field on the wire).
  DateTime? _resolveJoinedAt(BuildContext context) {
    if (widget.isMe) {
      final player = context.watch<PlayerProvider>().player;
      if (player.joinedAt.millisecondsSinceEpoch > 0) return player.joinedAt;
    }
    return widget.profile?.createdAt;
  }

  ProfileStatCard? _buildHeroCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
    DateTime? joinedAt,
  ) {
    final stats = widget.profile?.stats;
    final rows = <Widget>[];

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    if (stats != null) {
      _addIfNotNull(rows, row(
        key: 'hero.level',
        icon: Icons.shield_rounded,
        label: l10n.profileStatLevel,
        value: 'Lv ${stats.level}',
      ));
      _addIfNotNull(rows, row(
        key: 'hero.totalXp',
        icon: Icons.bolt_rounded,
        label: l10n.profileStatTotalXp,
        value: _formatInt(stats.totalXp),
      ));
      _addIfNotNull(rows, row(
        key: 'hero.unlockedAchievements',
        icon: Icons.emoji_events_rounded,
        label: l10n.profileStatUnlockedAchievements,
        value: _formatInt(stats.unlockedAchievementCount),
      ));
      _addIfNotNull(rows, row(
        key: 'hero.grantedRewards',
        icon: Icons.card_giftcard_rounded,
        label: l10n.profileStatGrantedRewards,
        value: _formatInt(stats.grantedRewardCount),
      ));
    }

    int? unlockedCount;
    if (widget.isMe) {
      final cosmetics = context.watch<CosmeticsProvider>();
      unlockedCount = cosmetics.state?.unlocked.length;
    } else {
      unlockedCount = widget.profile?.stats.cosmeticsUnlocked;
    }
    _addIfNotNull(rows, row(
      key: 'hero.cosmeticsUnlocked',
      icon: Icons.auto_awesome_rounded,
      label: l10n.profileStatCosmeticsUnlocked,
      value: _fmtIntOrDash(unlockedCount),
    ));

    if (joinedAt != null) {
      final days = DateTime.now().difference(joinedAt).inDays;
      _addIfNotNull(rows, row(
        key: 'hero.daysOnApp',
        icon: Icons.calendar_today_rounded,
        label: l10n.profileStatDaysOnApp,
        value: _formatInt(days < 0 ? 0 : days),
      ));
    }

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.military_tech_rounded,
      iconColor: Tokens.accent,
      title: l10n.profileStatsHeroTitle,
      headline: stats != null ? _LevelBadge(level: stats.level) : null,
      rows: rows,
      initiallyExpanded: false,
    );
  }

  /// Wraps the existing [HeroStreakStatsCard] so it lives alongside the
  /// other STATISTIKY cards. Visibility is card-level (one
  /// `streaks.allRecords` key) — per-row toggling would clutter the
  /// dense 5-domain table for no signal gain.
  ///
  /// When the streak card is in the owner's blacklist the foreign
  /// viewer sees nothing; the owner sees it intact with a muted
  /// "hidden" marker via the wrapping [_HiddenCardOverlay].
  Widget? _buildStreakCard(
    BuildContext context,
    _VisibilityResolver resolver,
  ) {
    const key = 'streaks.allRecords';
    if (!resolver.shouldRender(key)) return null;

    final stats = widget.profile?.stats;
    if (stats == null) return null;

    List<DomainStreakRow> rows;
    if (widget.isMe) {
      final progression = context.watch<ProgressionEngineProvider>();
      rows = [
        for (final domain in const [
          ProgressionDomain.steps,
          ProgressionDomain.nutrition,
          ProgressionDomain.sleep,
          ProgressionDomain.activity,
          ProgressionDomain.body,
        ])
          DomainStreakRow(
            domain: domain,
            currentStreak: progression.currentStreakForDomain(domain),
            bestStreak: progression.streakForDomain(domain).bestStreak,
          ),
      ];
    } else {
      rows = const [
        ProgressionDomain.steps,
        ProgressionDomain.nutrition,
        ProgressionDomain.sleep,
        ProgressionDomain.activity,
        ProgressionDomain.body,
      ]
          .map((domain) => DomainStreakRow(
                domain: domain,
                currentStreak: null,
                bestStreak: switch (domain) {
                  ProgressionDomain.steps => stats.bestStepsStreak,
                  ProgressionDomain.nutrition => stats.bestNutritionStreak,
                  _ => null,
                },
              ))
          .toList(growable: false);
    }

    final isEditing = _editing && widget.isMe;
    final isHidden = resolver.isHiddenFromOthers(key);

    final card = HeroStreakStatsCard(
      achievementsCount: stats.unlockedAchievementCount,
      rows: rows,
      editFooter: isEditing
          ? _StreakVisibilityToggle(
              hidden: _pendingOverrides.contains(key),
              onToggle: () => _toggleVisibility(key),
            )
          : null,
    );

    if (isHidden && !isEditing) {
      return Opacity(opacity: 0.45, child: card);
    }
    return card;
  }

  ProfileStatCard? _buildActivityCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
  ) {
    final rows = <Widget>[];

    int? stepsLifetime;
    int? stepsAvg;
    int? activeDays;

    if (widget.isMe) {
      final fitness = context.watch<FitnessProvider>();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 29);
      final end = DateTime(now.year, now.month, now.day);

      var lifetime = 0;
      var active = 0;
      for (final r in fitness.stepsHistory) {
        lifetime += r.steps;
        if (r.date.isAfter(start.subtract(const Duration(days: 1))) &&
            !r.date.isAfter(end) &&
            r.steps > 0) {
          active++;
        }
      }
      stepsLifetime = lifetime;
      stepsAvg = fitness.stepsAvgForRange(start, end).round();
      activeDays = active;
    } else {
      final s = widget.profile?.stats;
      stepsLifetime = s?.stepsLifetime;
      stepsAvg = s?.stepsAvg30d;
      activeDays = s?.activeDays30d;
    }

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
      String? secondary,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        secondary: secondary,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    _addIfNotNull(rows, row(
      key: 'activity.stepsLifetime',
      icon: Icons.directions_walk_rounded,
      label: l10n.profileStatStepsLifetime,
      value: _fmtIntOrDash(stepsLifetime),
    ));
    _addIfNotNull(rows, row(
      key: 'activity.stepsAvg30d',
      icon: Icons.show_chart_rounded,
      label: l10n.profileStatStepsAvg30d,
      value: _fmtIntOrDash(stepsAvg),
      secondary: '30 d',
    ));
    _addIfNotNull(rows, row(
      key: 'activity.activeDays30d',
      icon: Icons.event_available_rounded,
      label: l10n.profileStatActiveDays30d,
      value: _fmtIntOrDash(activeDays),
      secondary: '30 d',
    ));

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.directions_run_rounded,
      iconColor: const Color(0xFF60A5FA),
      title: l10n.profileStatsActivityTitle,
      rows: rows,
    );
  }

  ProfileStatCard? _buildSleepCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
  ) {
    final rows = <Widget>[];

    int? avgSleepMin;
    int? avgBedtimeMin;
    int? avgWakeMin;
    int? avgDeepMin;
    int? avgRemMin;

    if (widget.isMe) {
      final fitness = context.watch<FitnessProvider>();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 6);
      final end = DateTime(now.year, now.month, now.day);

      avgSleepMin = fitness.avgSleepForRange(start, end)?.inMinutes;

      final bedtimeMinutes = <int>[];
      final wakeMinutes = <int>[];
      var deepSum = 0;
      var remSum = 0;
      var nightsWithStage = 0;
      for (final r in fitness.sleepHistory) {
        if (r.wakeTime.isBefore(start) || r.sleepStart.isAfter(end)) continue;
        final bedRefMin = r.sleepStart.hour * 60 + r.sleepStart.minute;
        bedtimeMinutes
            .add(bedRefMin < 12 * 60 ? bedRefMin + 24 * 60 : bedRefMin);
        wakeMinutes.add(r.wakeTime.hour * 60 + r.wakeTime.minute);
        if (r.hasStageData) {
          nightsWithStage++;
          deepSum += r.deepDuration.inMinutes;
          remSum += r.remDuration.inMinutes;
        }
      }
      if (bedtimeMinutes.isNotEmpty) {
        avgBedtimeMin = (bedtimeMinutes.reduce((a, b) => a + b) ~/
                bedtimeMinutes.length) %
            (24 * 60);
      }
      if (wakeMinutes.isNotEmpty) {
        avgWakeMin =
            wakeMinutes.reduce((a, b) => a + b) ~/ wakeMinutes.length;
      }
      if (nightsWithStage > 0) {
        avgDeepMin = deepSum ~/ nightsWithStage;
        avgRemMin = remSum ~/ nightsWithStage;
      }
    } else {
      final s = widget.profile?.stats;
      avgSleepMin = s?.avgSleepMinutes7d;
      avgBedtimeMin = s?.avgBedtimeMinutes7d;
      avgWakeMin = s?.avgWakeMinutes7d;
      avgDeepMin = s?.avgDeepMinutes7d;
      avgRemMin = s?.avgRemMinutes7d;
    }

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
      String? secondary,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        secondary: secondary,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    _addIfNotNull(rows, row(
      key: 'sleep.avgDuration7d',
      icon: Icons.bedtime_rounded,
      label: l10n.profileStatSleepAvgDuration,
      value: _fmtMinutesOrDash(avgSleepMin),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'sleep.avgBedtime7d',
      icon: Icons.nights_stay_rounded,
      label: l10n.profileStatSleepAvgBedtime,
      value: _fmtClockOrDash(avgBedtimeMin),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'sleep.avgWakeTime7d',
      icon: Icons.wb_twilight_rounded,
      label: l10n.profileStatSleepAvgWakeTime,
      value: _fmtClockOrDash(avgWakeMin),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'sleep.avgDeep7d',
      icon: Icons.dark_mode_rounded,
      label: l10n.profileStatSleepAvgDeep,
      value: _fmtMinutesOrDash(avgDeepMin),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'sleep.avgRem7d',
      icon: Icons.brightness_3_rounded,
      label: l10n.profileStatSleepAvgRem,
      value: _fmtMinutesOrDash(avgRemMin),
      secondary: '7 d',
    ));

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.bedtime_rounded,
      iconColor: const Color(0xFFA78BFA),
      title: l10n.profileStatsSleepTitle,
      rows: rows,
    );
  }

  ProfileStatCard? _buildBodyCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
  ) {
    final rows = <Widget>[];
    double? weight;
    double? bodyFat;
    if (widget.isMe) {
      final fitness = context.watch<FitnessProvider>();
      weight = fitness.latestWeight;
      bodyFat = fitness.latestBodyFat;
    } else {
      final s = widget.profile?.stats;
      weight = s?.latestWeightKg;
      bodyFat = s?.latestBodyFatPct;
    }

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    _addIfNotNull(rows, row(
      key: 'body.latestWeight',
      icon: Icons.monitor_weight_rounded,
      label: l10n.profileStatLatestWeight,
      value: _fmtDoubleOrDash(weight, unit: 'kg'),
    ));
    _addIfNotNull(rows, row(
      key: 'body.latestBodyFat',
      icon: Icons.water_drop_rounded,
      label: l10n.profileStatLatestBodyFat,
      value: _fmtDoubleOrDash(bodyFat, unit: '%'),
    ));

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.fitness_center_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: l10n.profileStatsBodyTitle,
      rows: rows,
    );
  }

  ProfileStatCard? _buildNutritionCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
  ) {
    final rows = <Widget>[];

    double? kcal;
    double? protein;
    double? fat;
    double? carbs;
    if (widget.isMe) {
      final kt = context.watch<KalorickeTabulkyProvider>();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 6);
      final end = DateTime(now.year, now.month, now.day);
      final summary = kt.nutritionSummaryForRange(start, end);
      if (summary != null) {
        kcal = summary.calories;
        protein = summary.protein;
        fat = summary.fat;
        carbs = summary.carbs;
      }
    } else {
      final s = widget.profile?.stats;
      kcal = s?.avgKcal7d;
      protein = s?.avgProteinG7d;
      fat = s?.avgFatG7d;
      carbs = s?.avgCarbsG7d;
    }

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
      String? secondary,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        secondary: secondary,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    _addIfNotNull(rows, row(
      key: 'nutrition.avgKcal7d',
      icon: Icons.local_fire_department_rounded,
      label: l10n.profileStatAvgKcal,
      value: kcal == null ? '—' : '${kcal.round()} kcal',
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'nutrition.avgProtein7d',
      icon: Icons.egg_alt_rounded,
      label: l10n.profileStatAvgProtein,
      value: _fmtDoubleOrDash(protein, unit: 'g', digits: 0),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'nutrition.avgFat7d',
      icon: Icons.opacity_rounded,
      label: l10n.profileStatAvgFat,
      value: _fmtDoubleOrDash(fat, unit: 'g', digits: 0),
      secondary: '7 d',
    ));
    _addIfNotNull(rows, row(
      key: 'nutrition.avgCarbs7d',
      icon: Icons.grain_rounded,
      label: l10n.profileStatAvgCarbs,
      value: _fmtDoubleOrDash(carbs, unit: 'g', digits: 0),
      secondary: '7 d',
    ));

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.restaurant_rounded,
      iconColor: const Color(0xFFFB7185),
      title: l10n.profileStatsNutritionTitle,
      rows: rows,
    );
  }

  ProfileStatCard? _buildSocialCard(
    BuildContext context,
    AppLocalizations l10n,
    _VisibilityResolver resolver,
    DateTime? joinedAt,
  ) {
    final rows = <Widget>[];

    Widget? row({
      required String key,
      required IconData icon,
      required String label,
      required String value,
    }) {
      if (!resolver.shouldRender(key)) return null;
      final descriptor = profileStatDescriptorByKey(key);
      return ProfileStatRow(
        icon: icon,
        label: label,
        value: value,
        isHiddenFromOthers: resolver.isHiddenFromOthers(key),
        editMode: _editing && widget.isMe,
        ownerOnly: descriptor?.ownerOnly ?? false,
        onToggleHidden: () => _toggleVisibility(key),
      );
    }

    _addIfNotNull(rows, row(
      key: 'social.friendsCount',
      icon: Icons.group_rounded,
      label: l10n.profileStatFriendsCount,
      value: widget.friendCount == null ? '—' : _formatInt(widget.friendCount!),
    ));
    _addIfNotNull(rows, row(
      key: 'social.sharedPostsCount',
      icon: Icons.forum_rounded,
      label: l10n.profileStatSharedPostsCount,
      value: widget.sharedPostsCount == null
          ? '—'
          : _formatInt(widget.sharedPostsCount!),
    ));
    if (joinedAt != null) {
      _addIfNotNull(rows, row(
        key: 'social.joinedAt',
        icon: Icons.event_rounded,
        label: l10n.profileStatJoinedAt,
        value: _formatDate(joinedAt),
      ));
    }

    if (rows.isEmpty) return null;
    return ProfileStatCard(
      icon: Icons.diversity_3_rounded,
      iconColor: const Color(0xFF34D399),
      title: l10n.profileStatsSocialTitle,
      rows: rows,
    );
  }

  void _addIfNotNull(List<Widget> rows, Widget? row) {
    if (row != null) rows.add(row);
  }
}

class _VisibilityResolver {
  const _VisibilityResolver({
    required this.overrides,
    required this.isOwner,
    required this.editing,
  });

  /// XOR override set — membership means the user's choice differs
  /// from the catalog default for that key.
  final Set<String> overrides;
  final bool isOwner;
  final bool editing;

  /// Whether the row for [key] should be present in the widget tree.
  ///
  /// Owners always see every applicable row (foreign-hidden ones get
  /// a muted lock badge). Foreign viewers get the catalog + override
  /// XOR check via [isStatVisibleForViewer].
  bool shouldRender(String key) {
    return isStatVisibleForViewer(
      key: key,
      statVisibilityOverrides: overrides,
      isOwner: isOwner,
    );
  }

  /// Whether the row should render in the muted "hidden from others"
  /// style for the owner. Foreign viewers either see the row or
  /// don't, they never see the muted variant.
  bool isHiddenFromOthers(String key) {
    if (!isOwner) return false;
    final descriptor = profileStatDescriptorByKey(key);
    if (descriptor == null) return false;
    if (descriptor.ownerOnly) return true;
    // Same XOR check as the foreign resolver — owner sees muted when
    // the resolved foreign-visibility is false.
    final defaultVisible = !descriptor.defaultHidden;
    final overridden = overrides.contains(key);
    return defaultVisible == overridden;
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.l10n,
    required this.isOwner,
    required this.editing,
    required this.saving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final AppLocalizations l10n;
  final bool isOwner;
  final bool editing;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.bar_chart_rounded, size: 14, color: Tokens.accent),
        const SizedBox(width: Tokens.spaceSm),
        Expanded(
          child: Text(
            l10n.profileStatsSectionTitle,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              fontWeight: FontWeight.w800,
              color: Tokens.accent,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (!isOwner)
          const SizedBox.shrink()
        else if (editing) ...[
          TextButton(
            onPressed: saving ? null : onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white.withValues(alpha: 0.6),
            ),
            child: Text(l10n.profileStatsCancel),
          ),
          TextButton(
            onPressed: saving ? null : onSave,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Tokens.accent,
            ),
            child: saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Tokens.accent,
                    ),
                  )
                : Text(
                    l10n.profileStatsSave,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ] else
          IconButton(
            onPressed: onEdit,
            tooltip: l10n.profileStatsEdit,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            icon: Icon(
              Icons.edit_rounded,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}

/// Edit-mode visibility toggle row injected into the streak card's
/// expanded body via `HeroStreakStatsCard.editFooter`. Lives below
/// the per-domain rows inside the card itself — overlapping the
/// header's achievements pill would clash, but a row inside the
/// expanded body is unambiguous and tappable.
/// Edit-mode visibility toggle row injected into the streak card's
/// expanded body via `HeroStreakStatsCard.editFooter`. Mirrors the
/// per-row eye toggle pattern used by [ProfileStatRow] — icon-only,
/// right-aligned — so the streak card matches the other cards' edit
/// UX. The card stays freely expandable; tapping the row anywhere
/// flips the visibility key.
class _StreakVisibilityToggle extends StatelessWidget {
  const _StreakVisibilityToggle({
    required this.hidden,
    required this.onToggle,
  });

  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final mutedFg = Colors.white.withValues(alpha: 0.55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          children: [
            const Spacer(),
            Icon(
              hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: hidden ? mutedFg : Tokens.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Tokens.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Tokens.accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        'Lv $level',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Tokens.accent,
        ),
      ),
    );
  }
}

String _formatInt(int value) {
  final str = value.abs().toString();
  if (str.length <= 3) return value < 0 ? '-$str' : str;
  final buf = StringBuffer();
  var count = 0;
  for (var i = str.length - 1; i >= 0; i--) {
    buf.write(str[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write(' ');
      count = 0;
    }
  }
  final reversed = buf.toString().split('').reversed.join();
  return value < 0 ? '-$reversed' : reversed;
}

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h h ${m.toString().padLeft(2, '0')} min';
}

String _formatClock(int minutesSinceMidnight) {
  final h = (minutesSinceMidnight ~/ 60) % 24;
  final m = minutesSinceMidnight % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime dt) {
  return '${dt.day}. ${dt.month}. ${dt.year}';
}

String _fmtIntOrDash(int? value) => value == null ? '—' : _formatInt(value);

String _fmtDoubleOrDash(double? value, {required String unit, int digits = 1}) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(digits)} $unit';
}

String _fmtMinutesOrDash(int? minutes) =>
    minutes == null ? '—' : _formatMinutes(minutes);

String _fmtClockOrDash(int? minutesSinceMidnight) =>
    minutesSinceMidnight == null ? '—' : _formatClock(minutesSinceMidnight);
