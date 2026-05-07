import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class TabPill extends StatelessWidget {
  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChange;

  /// When provided, the active tab uses the domain's color + glow instead of
  /// the global accent. Lets the pill match the surrounding screen palette
  /// (e.g. sleep / steps / nutrition headers).
  final Domain? domain;

  const TabPill({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChange,
    this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final activeColor = domain?.color ?? ft.accent;
    final glowColor = domain?.glow ?? ft.accentGlow;

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
                              activeColor.withValues(alpha: 0.8),
                              activeColor.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: tab == active
                        ? [BoxShadow(color: glowColor, blurRadius: Tokens.glowMd)]
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
