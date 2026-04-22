import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ft_design_tokens.dart';
import '../features/health_connect/presentation/ft_activities_screen.dart';
import '../features/health_connect/presentation/ft_body_screen.dart';
import '../features/nutrition/presentation/ft_nutrition_screen.dart';
import 'ft_overview_screen.dart';

class FtMainShell extends StatefulWidget {
  const FtMainShell({super.key});

  @override
  State<FtMainShell> createState() => _FtMainShellState();
}

class _FtMainShellState extends State<FtMainShell> {
  int _index = 0;

  static const _screens = [
    FtOverviewScreen(),
    FtActivitiesScreen(),
    FtNutritionScreen(),
    FtBodyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: FtTokens.bg,
      ),
      child: Scaffold(
        backgroundColor: FtTokens.bg,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: _screens,
          ),
        ),
        bottomNavigationBar: _FtBottomNav(
          index: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _FtBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _FtBottomNav({required this.index, required this.onTap});

  static const _items = [
    _NavItem(label: 'Overview', icon: Icons.grid_view_rounded),
    _NavItem(label: 'Activities', icon: Icons.bolt_rounded),
    _NavItem(label: 'Nutrition', icon: Icons.local_fire_department_rounded),
    _NavItem(label: 'Body', icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: bottomPad + 10,
        left: 8,
        right: 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF20D0F1C),
        border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItemTile(
                item: _items[i],
                isActive: i == index,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

@immutable
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _NavItemTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                        FtTokens.accent.withValues(alpha: 0.20),
                        FtTokens.accent.withValues(alpha: 0.09),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? FtTokens.accent.withValues(alpha: 0.27)
                    : Colors.transparent,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: FtTokens.accentGlow, blurRadius: 10)]
                  : null,
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 22,
                color: isActive ? FtTokens.accent : const Color(0x59FFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: FtTokens.fontSizeMicro,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? FtTokens.accent : const Color(0x59FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
