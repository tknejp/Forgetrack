import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtTabPill extends StatelessWidget {
  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChange;

  const FtTabPill({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
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
                              FtTokens.accent.withValues(alpha: 0.8),
                              FtTokens.accent.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: tab == active
                        ? [BoxShadow(color: FtTokens.accentGlow, blurRadius: 12)]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: tab == active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: tab == active
                            ? Colors.white
                            : const Color(0x73FFFFFF),
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
