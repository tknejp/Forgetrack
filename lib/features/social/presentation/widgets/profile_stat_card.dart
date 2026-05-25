import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

/// Expandable card primitive shared by every section of the profile
/// stats area.
///
/// Mirrors the visual contract of [HeroStreakStatsCard]: subtle white
/// fill, hairline border, tap-to-expand chevron. Callers pass:
///   * [icon] + [title] for the header,
///   * an optional [headline] widget (small pill badge with the
///     marquee number for that card — Level, friend count, ...),
///   * [rows]: a list of [ProfileStatRow]s that render only when the
///     card is expanded.
///
/// The card is collapsed by default — the section is dense (5 cards
/// stacked) and forcing every visit to scroll past a wall of numbers
/// would crowd out the achievements / shared posts below it.
class ProfileStatCard extends StatefulWidget {
  const ProfileStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.rows,
    this.iconColor,
    this.headline,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? headline;
  final List<Widget> rows;
  final bool initiallyExpanded;

  @override
  State<ProfileStatCard> createState() => _ProfileStatCardState();
}

class _ProfileStatCardState extends State<ProfileStatCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final hasRows = widget.rows.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Tokens.radiusInner),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasRows ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.iconColor ?? Tokens.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (widget.headline != null) widget.headline!,
                if (hasRows) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: hasRows && _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        const SizedBox(height: 6),
                        for (var i = 0; i < widget.rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 2),
                          widget.rows[i],
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row inside a [ProfileStatCard].
///
/// Renders consistently across normal view, owner-view with hidden
/// rows (muted text + lock affordance), and edit mode (eye toggle).
class ProfileStatRow extends StatelessWidget {
  const ProfileStatRow({
    super.key,
    required this.label,
    required this.value,
    this.secondary,
    this.icon,
    this.iconColor,
    this.isHiddenFromOthers = false,
    this.editMode = false,
    this.onToggleHidden,
    this.ownerOnly = false,
  });

  /// Display label for the row (e.g. "Úroveň", "Avg kroky / den").
  final String label;

  /// Primary value text (e.g. "Lv 12", "8 432").
  final String value;

  /// Optional secondary value (e.g. "30 d" range hint). Rendered to
  /// the right of [value] in a muted style.
  final String? secondary;

  final IconData? icon;
  final Color? iconColor;

  /// Whether the row is in the owner's blacklist. Owner view shows it
  /// muted with a lock icon; edit mode shows it as the OFF state of
  /// the eye toggle.
  final bool isHiddenFromOthers;

  /// When true, the row renders the eye toggle on the right and the
  /// whole row becomes a tap target for [onToggleHidden].
  final bool editMode;

  /// True when the underlying data is owner-only on the wire format —
  /// renders an "owner only" badge in edit mode so the user knows
  /// toggling visibility is moot until the wire schema grows the field.
  final bool ownerOnly;

  final VoidCallback? onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.55);
    final faint = Colors.white.withValues(alpha: 0.35);
    final labelColor = isHiddenFromOthers ? muted : Colors.white;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? muted),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
          if (!editMode) ...[
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isHiddenFromOthers ? muted : Colors.white,
              ),
              textAlign: TextAlign.end,
            ),
            if (secondary != null) ...[
              const SizedBox(width: 6),
              Text(
                secondary!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: faint,
                ),
              ),
            ],
            if (isHiddenFromOthers) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline_rounded, size: 13, color: muted),
            ],
          ] else ...[
            if (ownerOnly) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text(
                  'jen pro mě',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: faint,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
            Icon(
              isHiddenFromOthers
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: isHiddenFromOthers ? muted : Tokens.accent,
            ),
          ],
        ],
      ),
    );

    if (!editMode) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ownerOnly ? null : onToggleHidden,
      child: Opacity(
        opacity: ownerOnly ? 0.65 : 1.0,
        child: content,
      ),
    );
  }
}
