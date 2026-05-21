import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';
import '../../nutrition/application/kaloricke_tabulky_provider.dart';
import '../domain/cosmetic_models.dart';
import 'cosmetics_provider.dart';
import 'food_trigger_service.dart';

const _log = AppLogger('COSMETICS', scope: 'foodTrigger');

/// Callback the provider invokes to actually credit XP. Kept as a
/// function instead of a hard reference to `ProgressionEngineProvider`
/// so unit tests can pass a fake without spinning up the engine.
typedef CompanionTriggerGrantFn = Future<void> Function({
  required int amount,
  required String periodKey,
});

/// Glue between the calorie log, the equipped companion, and the
/// progression engine for [Companion.foodTrigger] claims.
///
/// Behavior:
///   1. On listener change (calorie log adds/removes, equipped
///      companion swaps), recompute the snapshot for today.
///   2. Persist *only* the already-claimed XP under
///      `food_trigger.claimed.<yyyymmdd>.<companionId>`. The log
///      itself, the match result, and the cap math are all derived
///      on the fly — no schema to migrate when the catalog grows.
///   3. Calling [claim] writes a single [RewardGrantEvent] via the
///      injected grant callback and bumps the stored claimed total.
///
/// UI consumers can render unconditionally; when there is nothing to
/// claim, [currentSnapshot] returns null or a zero-claimable
/// snapshot — either way [hasClaimable] is false and the hidden
/// surfaces stay hidden.
class FoodTriggerProvider extends ChangeNotifier {
  FoodTriggerProvider({
    required KalorickeTabulkyProvider nutritionProvider,
    required CosmeticsProvider cosmeticsProvider,
    required CompanionTriggerGrantFn grant,
    FoodTriggerService service = const FoodTriggerService(),
    DateTime Function() now = DateTime.now,
  })  : _nutrition = nutritionProvider,
        _cosmetics = cosmeticsProvider,
        _grant = grant,
        _service = service,
        _now = now {
    _nutrition.addListener(_onInputsChanged);
    _cosmetics.addListener(_onInputsChanged);
  }

  /// Source of truth for today's logged food. KT is the only live
  /// nutrition log in the app today; if a manual / OFF source ever
  /// comes back, project it down to the same `List<String>` of
  /// titles and the service code does not need to change.
  final KalorickeTabulkyProvider _nutrition;
  final CosmeticsProvider _cosmetics;
  final CompanionTriggerGrantFn _grant;
  final FoodTriggerService _service;
  final DateTime Function() _now;

  static const _kPrefsPrefix = 'food_trigger.claimed';

  /// Cached claimed totals for today, keyed by companionId. Loaded
  /// from prefs on [init]; updated in-memory on [claim] (with a
  /// write-through to prefs).
  Map<String, int> _claimedToday = const {};
  String _claimedDayKey = '';
  bool _ready = false;
  bool _claiming = false;

  bool get isReady => _ready;
  bool get isClaiming => _claiming;

  /// Snapshot for the currently equipped companion's trigger, or
  /// null when nothing is equipped / equipped companion has no
  /// trigger / provider not ready yet. UI hides every surface when
  /// `snapshot.hasClaimable == false`.
  FoodTriggerSnapshot? get currentSnapshot {
    if (!_ready) return null;
    final companion = _equippedCompanion();
    if (companion == null) return null;
    return _service.evaluate(
      companion: companion,
      todayFoodNames: _collectTodayFoodNames(),
      alreadyClaimedXpToday: _claimedToday[companion.id.raw] ?? 0,
    );
  }

  /// Flattens [KalorickeTabulkyProvider.todayMeals] down to the list
  /// of foodstuff titles. Kept as a tiny private helper instead of a
  /// getter on the KT provider so the projection lives next to the
  /// consumer that needs it; if another nutrition source ever joins
  /// the trigger pipeline, this is the one place that grows.
  List<String> _collectTodayFoodNames() {
    final meals = _nutrition.todayMeals;
    if (meals.isEmpty) return const [];
    final out = <String>[];
    for (final meal in meals) {
      for (final f in meal.foodstuff) {
        out.add(f.title);
      }
    }
    return out;
  }

  /// Loads today's already-claimed totals from prefs. Old keys (for
  /// days other than today) are pruned eagerly so the prefs file
  /// does not grow unbounded.
  Future<void> init() async {
    final dayKey = _dayKey(_now());
    final prefs = await SharedPreferences.getInstance();
    final fresh = <String, int>{};
    final stale = <String>[];
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('$_kPrefsPrefix.')) continue;
      final rest = k.substring('$_kPrefsPrefix.'.length);
      final dot = rest.indexOf('.');
      if (dot <= 0) {
        stale.add(k);
        continue;
      }
      final keyDay = rest.substring(0, dot);
      final companionId = rest.substring(dot + 1);
      if (keyDay == dayKey) {
        fresh[companionId] = prefs.getInt(k) ?? 0;
      } else {
        stale.add(k);
      }
    }
    for (final k in stale) {
      await prefs.remove(k);
    }
    _claimedToday = fresh;
    _claimedDayKey = dayKey;
    _ready = true;
    notifyListeners();
  }

  /// Devtools — drop every stored claim total. Pairs with
  /// [ProgressionEngineProvider.devToolsWipeLedger]: once the ledger
  /// is gone, the engine no longer remembers granted XP, but the
  /// per-day claim ledger we keep in [SharedPreferences] still does
  /// — leaving the food-trigger pill stuck in its claimed state and
  /// blocking re-tests on the same day. Calling this from the wipe
  /// flow restores parity. Factory reset bypasses this on purpose
  /// because it clears all prefs wholesale (see
  /// `FactoryResetService.clearSharedPreferences`).
  Future<void> devToolsResetClaims() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = <String>[];
    for (final k in prefs.getKeys()) {
      if (!k.startsWith('$_kPrefsPrefix.')) continue;
      removed.add(k);
    }
    for (final k in removed) {
      await prefs.remove(k);
    }
    _claimedToday = const {};
    _log.info('devToolsResetClaims: dropped ${removed.length} keys');
    notifyListeners();
  }

  /// Attempts to claim whatever XP the equipped companion's trigger
  /// owes against today's log. Returns the granted amount (0 when
  /// nothing was claimable or the operation was suppressed).
  Future<int> claim() async {
    if (_claiming) return 0;
    final snap = currentSnapshot;
    if (snap == null || !snap.hasClaimable) return 0;

    _claiming = true;
    notifyListeners();
    try {
      // Re-check the day key — the player may have crossed midnight
      // with the app open; if so, today's claimed total resets and
      // the snapshot we computed above is stale.
      final dayKey = _dayKey(_now());
      if (dayKey != _claimedDayKey) {
        _claimedToday = const {};
        _claimedDayKey = dayKey;
      }

      final periodKey = '$dayKey.${snap.companion.id.raw}';
      await _grant(amount: snap.claimableXp, periodKey: periodKey);

      final companionId = snap.companion.id.raw;
      final newClaimed =
          (_claimedToday[companionId] ?? 0) + snap.claimableXp;
      _claimedToday = {..._claimedToday, companionId: newClaimed};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$_kPrefsPrefix.$dayKey.$companionId',
        newClaimed,
      );

      _log.info(
        'claim: companion=$companionId granted=${snap.claimableXp} '
        'todayTotal=$newClaimed matches=${snap.matchedEntryCount}',
      );
      return snap.claimableXp;
    } catch (e) {
      _log.warn('claim failed — $e');
      return 0;
    } finally {
      _claiming = false;
      notifyListeners();
    }
  }

  void _onInputsChanged() {
    // Roll the day key if the calorie log changed across midnight —
    // cheap, runs once per change.
    final dayKey = _dayKey(_now());
    if (dayKey != _claimedDayKey && _ready) {
      _claimedToday = const {};
      _claimedDayKey = dayKey;
    }
    notifyListeners();
  }

  Companion? _equippedCompanion() {
    final state = _cosmetics.state;
    if (state == null) return null;
    final equippedId = state.equipped.companionId;
    if (equippedId == null) return null;
    final def = _cosmetics.service.catalog.byId(equippedId);
    if (def is! Companion || !def.isEnabled) return null;
    return def;
  }

  String _dayKey(DateTime dt) => DateFormat('yyyyMMdd').format(dt);

  @override
  void dispose() {
    _nutrition.removeListener(_onInputsChanged);
    _cosmetics.removeListener(_onInputsChanged);
    super.dispose();
  }
}
