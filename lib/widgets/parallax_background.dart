import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../providers/time_theme_provider.dart';

// ─── Static fallback assets ────────────────────────────────────────────────────

const _kDayAsset   = 'assets/ui/gradient_light.jpg';
const _kNightAsset = 'assets/ui/gradient_dark.jpg';

// ─── Tuning ───────────────────────────────────────────────────────────────────

/// Image rendered at 2× screen width — the surplus allows horizontal tab pan.
const _kWidthFactor = 2.0;

/// Image rendered at 1.14× screen height — surplus allows vertical parallax.
const _kHeightFactor = 1.14;

/// Ratio of background upward movement to scroll distance (0–1).
const _kVerticalRate = 0.14;

/// Duration of the animated tab-switch pan.
const _kTabAnimDuration = Duration(milliseconds: 460);

/// Duration of the cross-fade between background images on scene change.
const _kCrossfadeDuration = Duration(milliseconds: 700);

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Full-screen parallax background that optionally adapts to the time of day.
///
/// When [TimeThemeProvider.enabled] is true the background image and scrim
/// track [TimeThemeProvider.visuals] and cross-fade smoothly whenever the
/// segment changes.  When disabled, the widget falls back to the static
/// day/night selection driven by [Brightness].
///
/// Place this as the first child in the outer app [Stack] so all content
/// renders on top of it.  Set `backgroundColor: Colors.transparent` on every
/// inner [Scaffold] so the image shows through.
class ParallaxBackground extends StatefulWidget {
  final int tabIndex;
  final int tabCount;

  /// Updated by the active scroll view.  The background listens independently
  /// so the parent widget never has to rebuild on scroll events.
  final ValueListenable<double> scrollNotifier;

  const ParallaxBackground({
    super.key,
    required this.tabIndex,
    required this.tabCount,
    required this.scrollNotifier,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with TickerProviderStateMixin {
  // ── Tab-pan animation ──────────────────────────────────────────────────────
  late final AnimationController _tabCtrl;
  late final Animation<double> _tabCurved;

  double _fromFraction = 0.0;
  double _toFraction   = 0.0;

  double get _currentFraction =>
      lerpDouble(_fromFraction, _toFraction, _tabCurved.value)!;

  // ── Asset cross-fade ───────────────────────────────────────────────────────

  /// Starts at 1.0 so the initial asset is fully opaque from frame one.
  late final AnimationController _crossfadeCtrl;
  late final Animation<double> _crossfadeCurved;

  /// The currently active (fully visible) background asset path.
  String _activeAsset = '';

  /// The outgoing asset rendered at full opacity beneath the incoming one.
  /// Cleared once the cross-fade completes.
  String _fadingAsset = '';

  /// Guard so [didChangeDependencies] only sets the initial asset once.
  bool _initialized = false;

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fromFraction = _tabFraction(widget.tabIndex);
    _toFraction   = _fromFraction;
    _tabCtrl = AnimationController(vsync: this, duration: _kTabAnimDuration);
    _tabCurved = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeInOutCubic);

    // value: 1.0 → active image renders fully opaque on the very first frame.
    _crossfadeCtrl = AnimationController(
      vsync: this,
      duration: _kCrossfadeDuration,
      value: 1.0,
    );
    _crossfadeCurved = CurvedAnimation(
      parent: _crossfadeCtrl,
      curve: Curves.easeInOut,
    );
    _crossfadeCtrl.addStatusListener((status) {
      // Once the incoming image is fully visible, remove the outgoing layer.
      if (status == AnimationStatus.completed && mounted && _fadingAsset.isNotEmpty) {
        setState(() => _fadingAsset = '');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Set the initial asset without animation — controller is already at 1.0.
      _activeAsset = _resolveAsset(context);
    }
  }

  @override
  void didUpdateWidget(ParallaxBackground old) {
    super.didUpdateWidget(old);
    if (old.tabIndex != widget.tabIndex) {
      _fromFraction = _currentFraction; // snapshot current mid-animation pos
      _toFraction   = _tabFraction(widget.tabIndex);
      _tabCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _crossfadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _tabFraction(int index) =>
      widget.tabCount <= 1 ? 0.0 : index / (widget.tabCount - 1);

  String _resolveAsset(BuildContext context) {
    final timeProvider = context.read<TimeThemeProvider>();
    if (timeProvider.enabled) return timeProvider.visuals.backgroundAsset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _kNightAsset : _kDayAsset;
  }

  Color _resolveScrim(BuildContext context, TimeThemeProvider timeProvider) {
    if (timeProvider.enabled) return timeProvider.visuals.scrimColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0x85000000) : const Color(0x61FFFFFF);
  }

  void _startCrossfade(String newAsset) {
    if (!mounted || newAsset == _activeAsset) return;
    setState(() {
      _fadingAsset = _activeAsset;
      _activeAsset = newAsset;
    });
    _crossfadeCtrl.forward(from: 0.0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final timeProvider  = context.watch<TimeThemeProvider>();
    final targetAsset   = timeProvider.enabled
        ? timeProvider.visuals.backgroundAsset
        : (isDark ? _kNightAsset : _kDayAsset);
    final scrimColor    = _resolveScrim(context, timeProvider);

    // Schedule cross-fade after this frame if the desired asset changed.
    if (_initialized && targetAsset != _activeAsset) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startCrossfade(targetAsset);
      });
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_tabCurved, widget.scrollNotifier, _crossfadeCurved]),
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final W = size.width;
          final H = size.height;

          final imgW = W * _kWidthFactor;
          final imgH = H * _kHeightFactor;
          final maxVShift = H * (_kHeightFactor - 1.0);

          // Horizontal: tab 0 = left edge of image, last tab = right edge.
          final hShift = -_currentFraction * (imgW - W);

          // Vertical: image moves up as user scrolls down.
          final vShift =
              (-widget.scrollNotifier.value * _kVerticalRate).clamp(-maxVShift, 0.0);

          return ClipRect(
            child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Outgoing image: stays at full opacity below the incoming one
                  // so there is never a transparent gap during the fade.
                  if (_fadingAsset.isNotEmpty)
                    _imageLayer(
                      key: ValueKey('fading:$_fadingAsset'),
                      asset: _fadingAsset,
                      hShift: hShift, vShift: vShift,
                      imgW: imgW, imgH: imgH,
                      opacity: 1.0,
                      fallback: isDark ? _kNightAsset : _kDayAsset,
                    ),
                  // Incoming / steady-state image: fades in 0 → 1.
                  if (_activeAsset.isNotEmpty)
                    _imageLayer(
                      key: ValueKey('active:$_activeAsset'),
                      asset: _activeAsset,
                      hShift: hShift, vShift: vShift,
                      imgW: imgW, imgH: imgH,
                      opacity: _crossfadeCurved.value,
                      fallback: isDark ? _kNightAsset : _kDayAsset,
                    ),
                  // Scrim: animates smoothly when the colour changes.
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: _kCrossfadeDuration,
                      curve: Curves.easeInOut,
                      color: scrimColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imageLayer({
    required Key key,
    required String asset,
    required double hShift,
    required double vShift,
    required double imgW,
    required double imgH,
    required double opacity,
    required String fallback,
  }) {
    return Positioned(
      key: key,
      left: hShift,
      top: vShift,
      width: imgW,
      height: imgH,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Image.asset(
            fallback,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
