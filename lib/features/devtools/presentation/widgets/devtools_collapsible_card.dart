import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Collapsible variant of [DevToolsSectionCard]. Used to fold rarely-
/// touched controls (inspect counters, XP/level overrides) so the
/// devtools page reads as a focused action surface — most taps land
/// in the top two cards, and the secondary stuff stays out of the way
/// until needed.
class DevToolsCollapsibleCard extends StatefulWidget {
  const DevToolsCollapsibleCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    this.leadingIcon,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? leadingIcon;

  @override
  State<DevToolsCollapsibleCard> createState() =>
      _DevToolsCollapsibleCardState();
}

class _DevToolsCollapsibleCardState extends State<DevToolsCollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(Tokens.radiusInner),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(widget.leadingIcon, size: 17, color: cs.onSurface),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Tokens.cardBorder,
                      ),
                      ...widget.children,
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
