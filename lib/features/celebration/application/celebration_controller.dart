import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../progression_engine/application/progression_engine_provider.dart';
import '../domain/models/celebration_event.dart';
import 'progression_engine_celebration_adapter.dart';

/// Bridges the V2 progression engine's celebration queue to the
/// celebration feature's UI. Owns:
///   * the event-conversion adapter
///     ([ProgressionEngineCelebrationAdapter]),
///   * the "current event" the overlay host should render,
///   * the claim relay back to [ProgressionEngineProvider].
///
/// Lifecycle: instantiated as a `ChangeNotifierProxyProvider2` of
/// [ProgressionEngineProvider] + [CosmeticsProvider]. Whenever the
/// upstream V2 provider notifies listeners, the controller checks if
/// there is a new celebration to show.
///
/// Phase 9b: cut over from the legacy `ProgressionProvider`. The
/// adapter (`ProgressionEngineCelebrationAdapter`) returns a list of
/// [CelebrationEvent]s per resolution result; we surface the first
/// immediately and stash the rest in [_buffered] so a single
/// resolution can play several overlays in sequence as the user
/// dismisses each one.
class CelebrationController extends ChangeNotifier {
  CelebrationController() : _adapter = null, _progression = null;

  ProgressionEngineProvider? _progression;
  ProgressionEngineCelebrationAdapter? _adapter;
  CelebrationEvent? _current;
  final Queue<CelebrationEvent> _buffered = Queue<CelebrationEvent>();
  bool _bound = false;

  CelebrationEvent? get current => _current;

  /// Wire the upstream providers. Safe to call repeatedly with the same
  /// instances (idempotent); listener registration is reference-counted.
  void bind({
    required ProgressionEngineProvider progression,
    required CosmeticsProvider cosmetics,
  }) {
    final progressionChanged = _progression != progression;
    final cosmeticsChanged =
        _adapter == null || _adapter!.cosmetics != cosmetics;

    if (progressionChanged) {
      _progression?.removeListener(_onProgressionChanged);
      _progression = progression;
      _progression!.addListener(_onProgressionChanged);
    }
    if (progressionChanged || cosmeticsChanged) {
      _adapter = ProgressionEngineCelebrationAdapter(cosmetics: cosmetics);
    }
    _bound = true;
    // bind() runs during the proxy provider's update phase, which is part
    // of the build pipeline. Calling notifyListeners synchronously from
    // here (which _drain may do) breaks consumers mid-build. Defer to a
    // microtask so the rest of the frame settles first.
    Future.microtask(_drain);
  }

  void _onProgressionChanged() => _drain();

  void _drain() {
    if (!_bound) return;
    if (_current != null) return;

    // First, replay any events buffered from a prior multi-event result.
    if (_buffered.isNotEmpty) {
      _current = _buffered.removeFirst();
      notifyListeners();
      return;
    }

    // Take the next pending resolution result from V2.
    final adapter = _adapter;
    if (adapter == null) return;
    while (_current == null) {
      final next = _progression?.takePendingCelebration();
      if (next == null) return;
      final events = adapter.convert(next);
      if (events.isEmpty) continue; // skip results with no UI-worthy events
      _current = events.first;
      for (var i = 1; i < events.length; i++) {
        _buffered.add(events[i]);
      }
    }
    notifyListeners();
  }

  /// Called by the overlay host once the current celebration has been
  /// dismissed (topsheet swiped/tapped close, fullscreen popped). The next
  /// queued event, if any, will be promoted to [current].
  void dismiss() {
    if (_current == null) return;
    _current = null;
    notifyListeners();
    // Promote the next event on the next frame so listeners see a clean
    // null transition first — otherwise the host can race and try to
    // render the new one inside the same frame as the old.
    Future.microtask(_drain);
  }

  /// Idempotent — relays to [ProgressionEngineProvider.claimNode]. Safe
  /// to call even after the user already claimed from a quest card.
  Future<void> claim(String rewardKey) async {
    await _progression?.claimNode(nodeId: rewardKey);
  }

  @override
  void dispose() {
    _progression?.removeListener(_onProgressionChanged);
    super.dispose();
  }
}
