import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/ft_design_tokens.dart';
import '../../domain/journey_models.dart';
import 'journey_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Interactive map — pannable canvas with checkpoints + on-tap tooltip overlay.
// ─────────────────────────────────────────────────────────────────────────────

/// Big interactive journey map for `HeroJourneyMapScreen`.
///
/// The map fills the explicit [height] passed by the screen; the inner virtual
/// canvas is roughly twice as tall so the user can pan vertically through the
/// timeline. Selection is controlled by the parent — pass `null` to start with
/// no checkpoint expanded; the tooltip's X button calls back with `null`.
class JourneyInteractiveMap extends StatefulWidget {
  const JourneyInteractiveMap({
    super.key,
    required this.checkpoints,
    required this.selectedIndex,
    required this.onSelected,
    required this.height,
  });

  final List<JourneyCheckpoint> checkpoints;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;
  final double height;

  // Relative positions (x%, y%) along a tall winding canvas.
  // Index 0 = newest (top), last = oldest (bottom).
  static const List<Offset> _kRelPositions = [
    Offset(0.50, 0.035),
    Offset(0.78, 0.105),
    Offset(0.42, 0.170),
    Offset(0.18, 0.232),
    Offset(0.62, 0.295),
    Offset(0.82, 0.360),
    Offset(0.46, 0.425),
    Offset(0.20, 0.490),
    Offset(0.55, 0.555),
    Offset(0.80, 0.620),
    Offset(0.42, 0.685),
    Offset(0.18, 0.750),
    Offset(0.60, 0.815),
    Offset(0.30, 0.885),
    Offset(0.55, 0.950),
  ];

  @override
  State<JourneyInteractiveMap> createState() => _JourneyInteractiveMapState();
}

class _JourneyInteractiveMapState extends State<JourneyInteractiveMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final viewportH = widget.height;
        final canvasH = viewportH * 2.0;
        final n = widget.checkpoints.length
            .clamp(0, JourneyInteractiveMap._kRelPositions.length);

        final absPos = List<Offset>.generate(n, (i) {
          final rel = JourneyInteractiveMap._kRelPositions[i];
          return Offset(rel.dx * viewportW, rel.dy * canvasH);
        });

        final selected = widget.selectedIndex;
        final hasSelection = selected != null && selected >= 0 && selected < n;

        return Container(
          width: viewportW,
          height: viewportH,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1838), Color(0xFF0F1226)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: FtTokens.accent.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Pannable canvas (everything map-related lives inside,
                //    so map gestures don't fight with parent scroll). ───────
                InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  panEnabled: true,
                  scaleEnabled: false,
                  boundaryMargin: const EdgeInsets.symmetric(vertical: 60),
                  child: SizedBox(
                    width: viewportW,
                    height: canvasH,
                    child: Stack(
                      children: [
                        _MapBackground(width: viewportW, height: canvasH),
                        if (absPos.length >= 2)
                          CustomPaint(
                            size: Size(viewportW, canvasH),
                            painter: JourneyPathPainter(
                              nodePositions: absPos,
                              pathColor: FtTokens.accent,
                              dashedHeadCount: _dashedHeadCount(),
                            ),
                          ),
                        for (int i = 0; i < n; i++)
                          Positioned(
                            left: absPos[i].dx -
                                _halfNodeWidget(widget.checkpoints[i]),
                            top: absPos[i].dy -
                                _halfNodeWidget(widget.checkpoints[i]),
                            child: JourneyCheckpointNode(
                              checkpoint: widget.checkpoints[i],
                              isSelected: selected == i,
                              onTap: () => widget.onSelected(i),
                              baseSize: _nodeSize(widget.checkpoints[i]),
                              pulseAnimation: widget.checkpoints[i].isCurrent
                                  ? _pulse
                                  : null,
                            ),
                          ),
                        // Tooltip lives inside the canvas so it pans with the
                        // map and stays anchored to the selected node.
                        if (hasSelection)
                          _TooltipPosition(
                            anchor: absPos[selected],
                            canvasWidth: viewportW,
                            canvasHeight: canvasH,
                            child: JourneyCheckpointOverlayCard(
                              checkpoint: widget.checkpoints[selected],
                              onClose: () => widget.onSelected(null),
                              maxWidth: 240,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Pan hint pill (top-right, fixed in viewport, dim) ────────
                Positioned(
                  top: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe_vertical_rounded,
                              size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            'Posuň pro více',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.78),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 1 when the first checkpoint is a locked future milestone (so the
  /// painter draws the leading 0→1 segment dashed), 0 otherwise.
  int _dashedHeadCount() {
    if (widget.checkpoints.isEmpty) return 0;
    return widget.checkpoints.first.isUnlocked ? 0 : 1;
  }

  static double _nodeSize(JourneyCheckpoint cp) => cp.isCurrent ? 30.0 : 22.0;

  static double _halfNodeWidget(JourneyCheckpoint cp) =>
      (_nodeSize(cp) + 26) / 2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tooltip positioning helper — places the overlay card next to the anchor
// node and clamps it to the canvas bounds so it never disappears off the edge.
// ─────────────────────────────────────────────────────────────────────────────

class _TooltipPosition extends StatelessWidget {
  const _TooltipPosition({
    required this.anchor,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.child,
  });

  final Offset anchor;
  final double canvasWidth;
  final double canvasHeight;
  final Widget child;

  // Reserve space; the card's intrinsic content may be shorter, but we need
  // an upper bound to clamp the position so the tooltip fits inside the
  // visible map canvas.
  static const double _tooltipMaxWidth = 240;
  static const double _tooltipApproxHeight = 130;
  static const double _nodeRadius = 18;
  static const double _gap = 10;
  static const double _edgePadding = 8;

  @override
  Widget build(BuildContext context) {
    final placeRight = anchor.dx < canvasWidth * 0.55;

    double left = placeRight
        ? anchor.dx + _nodeRadius + _gap
        : anchor.dx - _nodeRadius - _gap - _tooltipMaxWidth;
    left = left.clamp(
      _edgePadding,
      canvasWidth - _tooltipMaxWidth - _edgePadding,
    );

    double top = anchor.dy - _tooltipApproxHeight / 2;
    top = top.clamp(
      _edgePadding,
      canvasHeight - _tooltipApproxHeight - _edgePadding,
    );

    return Positioned(
      left: left,
      top: top,
      width: _tooltipMaxWidth,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map background — gradient + radial glows + optional asset.
// ─────────────────────────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/ui/journey_map_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/ui/journey_map_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _Glow(size: 280, color: FtTokens.accent, alpha: 0.22),
          ),
          Positioned(
            top: height * 0.4,
            right: -80,
            child: _Glow(size: 240, color: FtTokens.active.color, alpha: 0.14),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _Glow(size: 220, color: FtTokens.accent, alpha: 0.12),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(
      {required this.size, required this.color, required this.alpha});
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating tooltip overlay — compact, dismissable. Anchored next to the
// selected checkpoint inside the map canvas (pans with the map).
// ─────────────────────────────────────────────────────────────────────────────

class JourneyCheckpointOverlayCard extends StatelessWidget {
  const JourneyCheckpointOverlayCard({
    super.key,
    required this.checkpoint,
    this.onClose,
    this.maxWidth,
  });

  final JourneyCheckpoint checkpoint;

  /// Optional close handler. When supplied the card shows an X button.
  final VoidCallback? onClose;

  /// Optional width cap so the card behaves like a tooltip rather than a
  /// full-width overlay.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final cp = checkpoint;
    final color = journeyColor(cp.type);
    final locale = Localizations.localeOf(context).toString();
    final dateStr = cp.unlockedAt != null
        ? DateFormat('d. MMM yyyy', locale).format(cp.unlockedAt!)
        : null;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 6, 11),
      decoration: BoxDecoration(
        color: const Color(0xEE0F1226), // ~93% surface — readable yet floating
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  journeyTypeLabel(cp.type),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (cp.isCurrent) ...[
                const SizedBox(width: 5),
                const _CurrentDot(),
                const SizedBox(width: 3),
                const Text(
                  'TADY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.accent,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
              if (!cp.isUnlocked) ...[
                const SizedBox(width: 5),
                const Icon(Icons.lock_outline_rounded,
                    size: 10, color: FtTokens.onSurfaceFaint),
                const SizedBox(width: 2),
                const Text(
                  'ZAMČENO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: FtTokens.onSurfaceMuted,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
              const Spacer(),
              if (onClose != null)
                _CloseButton(color: color, onTap: onClose!),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: color.withValues(alpha: 0.32)),
                  ),
                  child: Center(child: _icon(cp, color)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cp.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (cp.sublabel != null || dateStr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _composeSubtitle(cp.sublabel, dateStr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cp.description != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                cp.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: FtTokens.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(cp.id),
        child: maxWidth != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth!),
                child: card,
              )
            : card,
      ),
    );
  }

  static String _composeSubtitle(String? sublabel, String? date) {
    if (sublabel != null && date != null) return '$sublabel · $date';
    return sublabel ?? date ?? '';
  }

  Widget _icon(JourneyCheckpoint cp, Color color) {
    if (cp.type == JourneyEventType.level && cp.levelNumber != null) {
      return Text(
        '${cp.levelNumber}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: cp.isUnlocked ? journeyFgColor(cp.type) : FtTokens.onSurfaceFaint,
          height: 1,
        ),
      );
    }
    return Icon(
      journeyIcon(cp.type),
      size: 16,
      color: cp.isUnlocked ? color : FtTokens.onSurfaceFaint,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: FtTokens.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _CurrentDot extends StatelessWidget {
  const _CurrentDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FtTokens.accent,
        boxShadow: [
          BoxShadow(
            color: FtTokens.accent.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
