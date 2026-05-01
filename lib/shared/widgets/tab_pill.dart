import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class TabPill extends StatelessWidget {
  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChange;

  const TabPill({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ft.divider,
        borderRadius: BorderRadius.circular(Tokens.radiusTile),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: tab == active
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ft.accent.withValues(alpha: 0.8),
                              ft.accent.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: tab == active
                        ? [BoxShadow(color: ft.accentGlow, blurRadius: Tokens.glowMd)]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            tab == active ? FontWeight.w700 : FontWeight.w500,
                        color: tab == active
                            ? ft.onSurface
                            : ft.onSurfaceMuted.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
