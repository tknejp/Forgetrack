part of '../profile_settings_widgets.dart';

class _ProfileTileTrailing extends StatelessWidget {
  final Widget? trailing;
  final String? trailingLabel;
  final bool showChevron;

  const _ProfileTileTrailing({
    required this.trailing,
    required this.trailingLabel,
    required this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final children = <Widget>[];

    if (trailing != null) {
      children.add(trailing!);
    } else if (trailingLabel != null) {
      children.add(
        Text(
          trailingLabel!,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (showChevron) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 4));
      }
      children.add(
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _ProfileIconBadge extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool compact;

  const _ProfileIconBadge({
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedIconColor = iconColor ?? cs.onSurfaceVariant;
    final bg = backgroundColor ??
        cs.surfaceContainerHigh.withValues(alpha: compact ? 0.8 : 0.72);
    final size = compact ? 32.0 : 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Icon(
        icon,
        size: compact ? 17 : 18,
        color: resolvedIconColor,
      ),
    );
  }
}
