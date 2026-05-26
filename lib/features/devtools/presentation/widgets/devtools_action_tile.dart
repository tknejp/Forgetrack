import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class DevToolsActionTile extends StatelessWidget {
  const DevToolsActionTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final effectivelyDisabled = isDisabled || isLoading || onTap == null;

    final labelColor = isDisabled
        ? cs.onSurfaceVariant.withValues(alpha: 0.4)
        : isDestructive
            ? cs.error
            : cs.onSurface;

    return InkWell(
      onTap: effectivelyDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: labelColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(
                          alpha: isDisabled ? 0.3 : 0.7,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            else if (isDisabled)
              Text(
                context.l10n.devtoolsActionDisabledBadge,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
