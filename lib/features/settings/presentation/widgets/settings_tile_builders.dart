part of 'settings_widgets.dart';

class _SettingsTileTrailing extends StatelessWidget {
  final Widget? trailing;
  final String? trailingLabel;
  final bool showChevron;

  const _SettingsTileTrailing({
    required this.trailing,
    required this.trailingLabel,
    required this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final children = <Widget>[];

    if (trailing != null) {
      children.add(trailing!);
    } else if (trailingLabel != null) {
      children.add(
        Text(
          trailingLabel!,
          style: tt.bodySmall?.copyWith(
            color: Tokens.onSurfaceMuted,
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
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Tokens.onSurfaceMuted,
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

class _SettingsIconBadge extends StatelessWidget {
  final IconData icon;
  final Widget? child;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool compact;

  const _SettingsIconBadge({
    required this.icon,
    this.child,
    this.iconColor,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Tokens.accent;
    final bg = backgroundColor ??
        Tokens.accent.withValues(alpha: compact ? 0.12 : 0.16);
    final size = compact ? 32.0 : 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(
          color: resolvedIconColor.withValues(alpha: compact ? 0.20 : 0.24),
        ),
      ),
      child: child ??
          Icon(
            icon,
            size: compact ? 17 : 18,
            color: resolvedIconColor,
          ),
    );
  }
}
