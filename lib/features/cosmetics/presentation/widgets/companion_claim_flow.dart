import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/cosmetics_provider.dart';
import '../../domain/cosmetic_models.dart';
import 'companion_claim_forging.dart';
import 'cosmetic_asset_thumb.dart';

/// State-machine entry widget for the companion claim flow.
///
/// Owns the four animation phases (`ready → forging → morphing → detail`)
/// that drive the hi-fi claim experience. The surrounding
/// [CosmeticDetailsSheet] renders the sheet shell (handle / badge /
/// title / hint); this widget renders only the interactive stage +
/// CTA, and (in later phases) the fullscreen forging overlay and
/// morphing handoff.
///
/// **C1 / C2 scope:** `ready` renders the silhouette + relic tiles +
/// primary CTA. Tapping the CTA inserts the fullscreen
/// [CompanionClaimForging] overlay and advances to the `forging`
/// phase. The overlay self-dismisses at t ≥ 5400 ms via the host's
/// [OverlayEntry] lifecycle. The morphing handoff (C3) and in-flow
/// detail body (C4) plug into the remaining branches.
enum CompanionClaimPhase {
  /// Resting state: silhouette + relic tiles + primary CTA.
  ready,

  /// Fullscreen ritual overlay (Orbita variant, 5.4 s).
  forging,

  /// 1.15 s handoff from overlay center → detail-sheet companion slot.
  morphing,

  /// Final companion details body (title / tags / unlock date /
  /// description / Vybavit CTA).
  detail,
}

class CompanionClaimFlow extends StatefulWidget {
  const CompanionClaimFlow({
    super.key,
    required this.companion,
    required this.relicIds,
    required this.color,
    required this.onClaim,
    this.destSlotKey,
    this.hideCompanion,
  });

  /// Companion catalog row — drives the silhouette → real-asset
  /// cross-fade and downstream detail rendering.
  final Cosmetic companion;

  /// Relic ids that gate the companion. Empty is allowed; the
  /// preview falls back to a generic glow ring.
  final List<String> relicIds;

  /// Accent color (typically the companion's rarity color).
  final Color color;

  /// Engine claim hook. Called by the forging overlay once the
  /// reveal frame lands (t ≈ 4700 ms). Parent should call
  /// `progression.claimNode(...)`.
  final Future<void> Function() onClaim;

  /// GlobalKey attached to the unlocked-layout companion avatar
  /// slot on [CosmeticDetailsSheet]. Lets the forging overlay morph
  /// the sprite into the sheet's slot at the end of the ritual. The
  /// surrounding sheet survives the rebuild from Claimable to Owned
  /// so the key remains valid through the handoff.
  final GlobalKey? destSlotKey;

  /// Notifier the unlocked-layout avatar slot watches to hide its
  /// native rendering during the morph handoff.
  final ValueNotifier<bool>? hideCompanion;

  @override
  State<CompanionClaimFlow> createState() => _CompanionClaimFlowState();
}

class _CompanionClaimFlowState extends State<CompanionClaimFlow>
    with TickerProviderStateMixin {
  CompanionClaimPhase _phase = CompanionClaimPhase.ready;

  /// Idle breathing animation for the silhouette + relic float.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  /// Re-entry guard: non-null once the overlay has been inserted,
  /// so a stray rebuild that re-enters [_startForging] does not
  /// double-insert. **Not cleared on dispose** — see [dispose].
  OverlayEntry? _forgingEntry;

  @override
  void dispose() {
    _idle.dispose();
    // Intentionally do NOT remove [_forgingEntry] here.
    //
    // The engine claim fires at the reveal frame (t=4700), which
    // flips the cosmetic to Owned. The surrounding details sheet
    // watches [CosmeticsProvider] and rebuilds its body away from
    // [_ClaimableCompanionBody] as soon as the grant lands —
    // disposing this state mid-ritual. If we yanked the overlay
    // here the forging settle (4800–5400) and the morph handoff
    // (1150 ms) would never play. The overlay's own widget owns
    // its lifecycle from this point on and removes itself via the
    // `onComplete` callback wired below.
    super.dispose();
  }

  void _startForging() {
    if (_phase != CompanionClaimPhase.ready) return;
    if (_forgingEntry != null) return;
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(
          widget.companion.previewAssetKey ?? widget.companion.assetKey,
        );
    // Cache the destSlotKey + hideCompanion locally so the
    // OverlayEntry's builder doesn't reach back into `widget`
    // after this state disposes (the engine claim rebuilds the
    // sheet away from us a few hundred ms before the morph runs).
    final destSlotKey = widget.destSlotKey;
    final hideCompanion = widget.hideCompanion;
    final companion = widget.companion;
    final relicIds = widget.relicIds;
    final color = widget.color;
    final onReveal = widget.onClaim;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => CompanionClaimForging(
        companion: companion,
        assetPath: assetPath,
        relicIds: relicIds,
        color: color,
        onReveal: onReveal,
        destSlotKey: destSlotKey,
        hideCompanion: hideCompanion,
        onComplete: entry.remove,
      ),
    );
    _forgingEntry = entry;
    overlay.insert(entry);
    setState(() => _phase = CompanionClaimPhase.forging);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case CompanionClaimPhase.ready:
        return _ReadyBody(
          companion: widget.companion,
          relicIds: widget.relicIds,
          color: widget.color,
          idle: _idle,
          onClaim: _startForging,
        );
      case CompanionClaimPhase.forging:
      case CompanionClaimPhase.morphing:
      case CompanionClaimPhase.detail:
        // The overlay owns the visuals once forging starts. C3
        // adds the morph handoff, C4 the in-flow detail body —
        // until then the parent sheet rebuilds into the regular
        // unlocked layout as soon as the engine grant lands and
        // this state is never observed at runtime.
        return const SizedBox.shrink();
    }
  }
}

/// `ready` phase body: outer breathing ring + silhouette + the two
/// gating relic thumbs floating either side + primary CTA. Visual
/// shape matches the prior placeholder reveal so C1's no-visual-diff
/// promise survives the C2 swap.
class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.companion,
    required this.relicIds,
    required this.color,
    required this.idle,
    required this.onClaim,
  });

  final Cosmetic companion;
  final List<String> relicIds;
  final Color color;
  final Animation<double> idle;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 240,
            height: 168,
            child: AnimatedBuilder(
              animation: idle,
              builder: (context, _) {
                return _IdleStage(
                  idle: idle.value,
                  color: color,
                  relicIds: relicIds,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ClaimCta(
          label: l10n.cosmeticCompanionClaimCta,
          color: color,
          onTap: onClaim,
        ),
      ],
    );
  }
}

class _IdleStage extends StatelessWidget {
  const _IdleStage({
    required this.idle,
    required this.color,
    required this.relicIds,
  });

  final double idle;
  final Color color;
  final List<String> relicIds;

  @override
  Widget build(BuildContext context) {
    final glowAlpha = 0.18 + 0.05 * idle;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha),
                  blurRadius: 38,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Transform.scale(
          scale: 0.94 + 0.06 * idle,
          child: _Silhouette(color: color),
        ),
        for (var i = 0; i < relicIds.length; i++)
          _RelicOrbiter(
            relicId: relicIds[i],
            color: color,
            idle: idle,
            angle: _angleFor(i, relicIds.length),
          ),
      ],
    );
  }

  static double _angleFor(int i, int total) {
    if (total <= 1) return -math.pi / 2;
    const arc = math.pi * 0.9;
    final start = -math.pi / 2 - arc / 2;
    return start + arc * (i / (total - 1));
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.34),
            color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Icon(
        Icons.pets_rounded,
        size: 56,
        color: color.withValues(alpha: 0.55),
      ),
    );
  }
}

class _RelicOrbiter extends StatelessWidget {
  const _RelicOrbiter({
    required this.relicId,
    required this.color,
    required this.idle,
    required this.angle,
  });

  final String relicId;
  final Color color;
  final double idle;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final radius = 78.0 + 4.0 * (idle - 0.5);
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: CosmeticAssetThumb(
        cosmeticId: relicId,
        size: 38,
        borderRadius: 10,
        fallbackColor: color,
      ),
    );
  }
}

class _ClaimCta extends StatelessWidget {
  const _ClaimCta({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Tokens.bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

