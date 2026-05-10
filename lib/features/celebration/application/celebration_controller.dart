import 'package:flutter/foundation.dart';

import '../../cosmetics/application/cosmetics_provider.dart';
import '../../progression/application/progression_provider.dart';
import '../domain/models/celebration_event.dart';
import 'progression_celebration_adapter.dart';

/// Bridges the progression layer's celebration queue to the celebration
/// feature's UI. Owns:
///   * the event-conversion adapter (progression → celebration domain),
///   * the "current event" the overlay host should render,
///   * the claim relay back to `ProgressionProvider`.
///
/// Lifecycle: instantiated as a `ChangeNotifierProxyProvider2` of
/// `ProgressionProvider` + `CosmeticsProvider`. Whenever the upstream
/// progression notifies listeners, the controller checks if there is a new
/// celebration to show.
class CelebrationController extends ChangeNotifier {
  CelebrationController() : _adapter = null, _progression = null;

  ProgressionProvider? _progression;
  ProgressionCelebrationAdapter? _adapter;
  CelebrationEvent? _current;
  bool _bound = false;

  CelebrationEvent? get current => _current;

  /// Wire the upstream providers. Safe to call repeatedly with the same
  /// instances (idempotent); listener registration is reference-counted.
  void bind({
    required ProgressionProvider progression,
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
      _adapter = ProgressionCelebrationAdapter(
        cosmetics: cosmetics,
        claim: (rewardKey) async {
          await _progression?.claimQuestReward(rewardKey);
        },
      );
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
    final next = _progression?.takeNextCelebration();
    if (next == null) return;
    final adapter = _adapter;
    if (adapter == null) return;
    _current = adapter.convert(next);
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

  /// Idempotent — relays to `ProgressionProvider.claimQuestReward`. Safe to
  /// call even after the user already claimed from a quest card.
  Future<void> claim(String rewardKey) async {
    await _progression?.claimQuestReward(rewardKey);
  }

  @override
  void dispose() {
    _progression?.removeListener(_onProgressionChanged);
    super.dispose();
  }
}
