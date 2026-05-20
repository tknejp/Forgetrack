import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Section header + container used by the V2 quests screen.
///
/// One row with a coloured uppercase label on the left and an optional
/// count chip on the right. Children render in a vertical list with
/// configurable spacing. Empty-state widget shown in place of the list
/// when [isEmpty] is true.
class EngineQuestSection extends StatelessWidget {
  const EngineQuestSection({
    super.key,
    required this.label,
    required this.color,
    required this.children,
    this.countLabel,
    this.isEmpty = false,
    this.empty,
    this.itemSpacing = Tokens.spaceSm,
  });

  final String label;
  final String? countLabel;
  final Color color;
  final bool isEmpty;
  final Widget? empty;
  final double itemSpacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 14, color: color),
            const SizedBox(width: Tokens.spaceSm),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            if (countLabel != null)
              Text(
                countLabel!,
                style: const TextStyle(
                  fontSize: Tokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  color: Tokens.onSurfaceMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (isEmpty)
          empty ?? const SizedBox.shrink()
        else
          Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: itemSpacing),
                children[i],
              ],
            ],
          ),
      ],
    );
  }
}

/// Compact in-card empty-state row: bold title + muted caption.
/// Used for "no daily goals today" / "no weekly quests" placeholders.
class EngineQuestEmptyLine extends StatelessWidget {
  const EngineQuestEmptyLine({
    super.key,
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: Tokens.fontSizeSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: Tokens.fontSizeCaption,
              height: 1.4,
              color: Tokens.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error banner styled to match the legacy progression
/// `ProgressionErrorBanner`. Shown above the list when the engine
/// surfaces a recovery-friendly error string.
class EngineQuestErrorBanner extends StatelessWidget {
  const EngineQuestErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22FBBF24),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: const Color(0x55FBBF24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: Tokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: Tokens.fontSizeSmall,
                height: 1.4,
                color: Tokens.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton block used by the quests screen while the
/// initial ledger hydrate is in flight.
class EngineQuestLoadingBlock extends StatelessWidget {
  const EngineQuestLoadingBlock({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }
}
