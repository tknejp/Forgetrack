import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'time_theme.dart';

/// Manages the opt-in Dynamic Time Theme feature.
///
/// The segment timer always runs after [init] so that both the background
/// toggle and the Dynamic theme mode (in [ThemeProvider]) get live segment
/// data — even when the background toggle is off.
///
/// [enabled] only controls whether [ParallaxBackground] swaps the background
/// image and scrim.  The palette and light/dark switching are driven by
/// [segment] regardless of this flag.
class TimeThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _prefKey = 'time_theme_enabled';

  bool _enabled = false;
  TimeSegment _segment = TimeSegment.morning;
  Timer? _timer;

  bool get enabled => _enabled;
  TimeSegment get segment => _segment;
  TimeThemeVisuals get visuals => TimeThemeResolver.visualsFor(_segment);

  /// Loads persisted preference and registers for app lifecycle callbacks.
  /// Must be called once before [runApp].
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    _segment = TimeThemeResolver.segmentFor(DateTime.now());
    _scheduleNextBoundary(); // always active — palette + dynamic mode need it
  }

  /// Enables or disables the background image feature and persists the choice.
  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  // Re-evaluate on resume in case the device was asleep through a boundary.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final fresh = TimeThemeResolver.segmentFor(DateTime.now());
    if (fresh != _segment) {
      _segment = fresh;
      notifyListeners();
    }
    _scheduleNextBoundary(); // re-anchor so the timer is exact from now
  }

  void _scheduleNextBoundary() {
    _timer?.cancel();
    final now = DateTime.now();
    final mins = TimeThemeResolver.minutesUntilNextSegment(now);
    // +1 s buffer so we land safely past the boundary minute.
    _timer = Timer(Duration(minutes: mins, seconds: 1), () {
      _segment = TimeThemeResolver.segmentFor(DateTime.now());
      notifyListeners();
      _scheduleNextBoundary();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
