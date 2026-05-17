import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../application/cosmetics_provider.dart';
import '../../domain/cosmetic_models.dart';
import '../cosmetics_screen_internals.dart';
import 'cosmetic_asset_thumb.dart';

/// Animated reveal of a companion as it's "forged" from its gating
/// relics. Renders inside the companion details sheet when the
/// companion is claimable (its `CompanionAvailability` is in
/// progression's `availableNodes` and its cosmetic id is not yet in the
/// unlocked map).
///
/// Lifecycle:
///   1. **Idle** — silhouette companion + two static relic thumbs +
///      pulsing "Vyzvedni" CTA.
///   2. **Forging** — relics orbit inward, then dive into the centre.
///      The silhouette warms up with a rarity glow and fades into the
///      real companion artwork once the relics arrive.
///   3. **Done** — `onClaim` is invoked. The parent rebuilds with the
///      regular details layout (companion now in unlocked map).
class CompanionClaimReveal extends StatefulWidget {
  const CompanionClaimReveal({
    super.key,
    required this.companion,
    required this.relicIds,
    required this.color,
    required this.onClaim,
  });

  final Cosmetic companion;

  /// Relic ids that gate the companion. Empty list still works — the
  /// silhouette + CTA stay; we just render a generic glow ring.
  final List<String> relicIds;

  /// Accent colour (typically the companion rarity).
  final Color color;

  /// Called once the forging animation finishes. Parent should call
  /// `progression.claimNode(...)` to grant the cosmetic.
  final Future<void> Function() onClaim;

  @override
  State<CompanionClaimReveal> createState() => _CompanionClaimRevealState();
}

class _CompanionClaimRevealState extends State<CompanionClaimReveal>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _forge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _busy = false;

  @override
  void dispose() {
    _idle.dispose();
    _forge.dispose();
    super.dispose();
  }

  Future<void> _trigger() async {
    if (_busy) return;
    setState(() => _busy = true);
    _idle.stop();
    await _forge.forward();
    if (!mounted) return;
    await widget.onClaim();
    // No setState here — parent rebuilds with the unlocked companion
    // and replaces this widget entirely.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assetPath = context
        .read<CosmeticsProvider>()
        .service
        .config
        .resolveAssetPath(
          widget.companion.previewAssetKey ?? widget.companion.assetKey,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 240,
            height: 168,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _forge]),
              builder: (context, _) {
                return _ForgeStage(
                  forge: _forge.value,
                  idle: _idle.value,
                  companion: widget.companion,
                  assetPath: assetPath,
                  relicIds: widget.relicIds,
                  color: widget.color,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _busy
              ? Padding(
                  key: const ValueKey('forging'),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    l10n.cosmeticCompanionClaimingFlavor,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.color.withValues(alpha: 0.9),
                      fontSize: Tokens.fontSizeSmall,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              : _ClaimCta(
                  key: const ValueKey('cta'),
                  label: l10n.cosmeticCompanionClaimCta,
                  color: widget.color,
                  onTap: _trigger,
                ),
        ),
      ],
    );
  }
}

class _ClaimCta extends StatelessWidget {
  const _ClaimCta({
    super.key,
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

/// Renders the silhouette + orbiting relics + reveal cross-fade for a
/// given `forge` progress (0..1) and continuous `idle` pulse (0..1).
class _ForgeStage extends StatelessWidget {
  const _ForgeStage({
    required this.forge,
    required this.idle,
    required this.companion,
    required this.assetPath,
    required this.relicIds,
    required this.color,
  });

  final double forge;
  final double idle;
  final Cosmetic companion;
  final String? assetPath;
  final List<String> relicIds;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final centre = const Alignment(0, 0);
    // Reveal threshold — silhouette stays opaque until ~70% of the
    // animation, then cross-fades into the real artwork as the relics
    // collide at the centre.
    final revealT = ((forge - 0.6) / 0.4).clamp(0.0, 1.0);
    final glowAlpha = 0.18 + 0.55 * forge + 0.05 * idle;

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
                  blurRadius: 38 + 18 * forge,
                  spreadRadius: 2 + 6 * forge,
                ),
              ],
            ),
          ),
        ),
        // Silhouette (idle / forging) — fades out as the reveal kicks in.
        Opacity(
          opacity: 1.0 - revealT,
          child: Transform.scale(
            scale: 0.94 + 0.06 * idle - 0.04 * forge,
            child: _Silhouette(color: color),
          ),
        ),
        // Real companion artwork — fades in for the final reveal.
        Opacity(
          opacity: revealT,
          child: Transform.scale(
            scale: 0.85 + 0.15 * revealT,
            child: CosmeticBadge(
              definition: companion,
              assetPath: assetPath,
              color: color,
              size: 128,
              framed: false,
              glow: true,
              fit: BoxFit.contain,
              contentScale: 1.2,
            ),
          ),
        ),
        // Relic thumbs — orbit slightly in idle, then dive towards centre.
        for (var i = 0; i < relicIds.length; i++)
          _RelicOrbiter(
            relicId: relicIds[i],
            color: color,
            forge: forge,
            idle: idle,
            angle: _angleFor(i, relicIds.length),
            centre: centre,
          ),
      ],
    );
  }

  double _angleFor(int i, int total) {
    if (total <= 1) return -math.pi / 2;
    // Spread relics symmetrically around the top arc so they read as
    // "ingredients hovering above the silhouette" rather than a ring.
    const arc = math.pi * 0.9; // ~162°
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
    required this.forge,
    required this.idle,
    required this.angle,
    required this.centre,
  });

  final String relicId;
  final Color color;
  final double forge;
  final double idle;
  final double angle;
  final Alignment centre;

  @override
  Widget build(BuildContext context) {
    // Outer radius shrinks from 78 → 0 as the forge animation runs;
    // idle adds a small breathing offset so the relics feel alive
    // before the player taps.
    final radius = 78.0 * (1.0 - forge) + 4.0 * (idle - 0.5);
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;
    final fade = 1.0 - ((forge - 0.7) / 0.3).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: 1.0 - 0.35 * forge,
          child: CosmeticAssetThumb(
            cosmeticId: relicId,
            size: 38,
            borderRadius: 10,
            fallbackColor: color,
          ),
        ),
      ),
    );
  }
}
