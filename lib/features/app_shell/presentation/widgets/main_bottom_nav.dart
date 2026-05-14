import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    this.questBadge = 0,
    this.socialBadge = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int questBadge;
  final int socialBadge;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;

    final items = <_NavItem>[
      _NavItem(label: l10n.navOverview, icon: Icons.grid_view_rounded),
      _NavItem(
        label: l10n.navQuests,
        icon: Icons.flag_rounded,
        badge: _badge(questBadge, ft.xp),
      ),
      _NavItem(label: l10n.navHero, icon: Icons.person_outline_rounded),
      _NavItem(
        label: l10n.navSocial,
        icon: Icons.groups_rounded,
        badge: _badge(socialBadge, ft.danger),
      ),
    ];

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding:
          EdgeInsets.only(top: 10, bottom: bottomPad + 10, left: 8, right: 8),
      decoration: BoxDecoration(
        color: ft.bg.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: ft.divider)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavItemTile(
                item: items[i],
                isActive: i == index,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }

  static _NavBadge? _badge(int count, Color color) =>
      count > 0 ? _NavBadge(count: count, color: color) : null;
}

@immutable
class _NavItem {
  const _NavItem({required this.label, required this.icon, this.badge});

  final String label;
  final IconData icon;
  final _NavBadge? badge;
}

@immutable
class _NavBadge {
  const _NavBadge({required this.count, required this.color});

  final int count;
  final Color color;
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ft.accent.withValues(alpha: 0.20),
                            ft.accent.withValues(alpha: 0.09),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                  border: Border.all(
                    color: isActive
                        ? ft.accent.withValues(alpha: 0.27)
                        : Colors.transparent,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: ft.accentGlow, blurRadius: 10)]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: isActive ? ft.accent : ft.onSurfaceFaint,
                  ),
                ),
              ),
              if (item.badge != null)
                Positioned(
                  top: -5,
                  right: -6,
                  child: _NavBadgePill(badge: item.badge!),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: Tokens.fontSizeMicro,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? ft.accent : ft.onSurfaceFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBadgePill extends StatelessWidget {
  const _NavBadgePill({required this.badge});

  final _NavBadge badge;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final isDarkBadge =
        ThemeData.estimateBrightnessForColor(badge.color) == Brightness.dark;
    final textColor = isDarkBadge
        ? Colors.white.withValues(alpha: 0.94)
        : ft.badgeTextOnLight;
    final label = badge.count > 9 ? '9+' : '${badge.count}';

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: badge.color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: badge.color.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: badge.color.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
