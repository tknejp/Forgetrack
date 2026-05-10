import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_log.dart';

/// Tracks whether the user has dismissed the first-launch welcome screen.
///
/// Stored as a single SharedPreferences flag so that:
///   * a fresh install / `prefs.clear()` (factory reset) re-shows it,
///   * the gate is reactive — flipping the flag triggers a routing rebuild
///     in `app.dart` without an app restart.
class OnboardingProvider extends ChangeNotifier {
  static const String prefsKey = 'onboarding_completed';

  bool _completed = false;
  bool _hydrated = false;

  /// True once the user has finished (or skipped) the welcome screen.
  /// While [isHydrated] is false, defaults to `false` so the welcome
  /// screen renders rather than briefly flashing the main shell.
  bool get isCompleted => _completed;

  /// True once [init] has read from prefs at least once.
  bool get isHydrated => _hydrated;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(prefsKey) ?? false;
    _hydrated = true;
    notifyListeners();
  }

  /// Marks onboarding finished. Idempotent.
  Future<void> markCompleted() async {
    if (_completed) return;
    _completed = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
    AppLog.app.info('onboarding: markCompleted persisted');
  }

  /// Re-reads the prefs flag. Used by DevTools factory reset after the
  /// wholesale `prefs.clear()` so the welcome screen re-appears in the
  /// running session without an app restart.
  Future<void> refresh() => init();
}
