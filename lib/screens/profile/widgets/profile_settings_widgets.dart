import 'package:flutter/material.dart';

class ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class ProfileTileDivider extends StatelessWidget {
  const ProfileTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class ProfileSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? trailingLabel;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? iconColor;
  final TextStyle? labelStyle;

  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingLabel,
    this.showChevron = false,
    this.onTap,
    this.iconColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? cs.onSurfaceVariant),
      title: Text(
        label,
        style: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: _buildTrailing(context),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (trailing != null) {
      return trailing;
    }

    if (trailingLabel != null) {
      return Text(
        trailingLabel!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (showChevron) {
      return Icon(
        Icons.chevron_right,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    return null;
  }
}

class ProfileSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ProfileSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SwitchListTile(
      secondary: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(label, style: tt.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class ProfileDropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const ProfileDropdownTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: cs.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
