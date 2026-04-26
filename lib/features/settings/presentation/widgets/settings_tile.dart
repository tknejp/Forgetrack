part of 'settings_widgets.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final String? trailingLabel;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final TextStyle? labelStyle;
  final bool compact;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.trailingLabel,
    this.showChevron = false,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.labelStyle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final verticalPadding = compact ? 10.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: verticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SettingsIconBadge(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: iconBackgroundColor,
                compact: compact,
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: labelStyle ??
                          (compact ? tt.bodyMedium : tt.bodyLarge)?.copyWith(
                            color: FtTokens.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: FtTokens.onSurfaceMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SettingsTileTrailing(
                trailing: trailing,
                trailingLabel: trailingLabel,
                showChevron: showChevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
