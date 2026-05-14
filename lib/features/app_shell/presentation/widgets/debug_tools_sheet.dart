import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';
import '../../../devtools/presentation/devtools_screen.dart';
import '../../../devtools/presentation/sections/devtools_cosmetics_section.dart';
import '../../../devtools/presentation/sections/devtools_progression_engine_section.dart';

Future<void> showDebugToolsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DebugToolsSheet(),
  );
}

class DebugLauncherButton extends StatelessWidget {
  const DebugLauncherButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: ft.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(Tokens.radiusInner),
          border: Border.all(color: ft.accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.bug_report_rounded,
          color: ft.accent,
          size: 20,
        ),
      ),
    );
  }
}

enum _DebugSheetTab {
  progression,
  cosmetics,
}

class _DebugToolsSheet extends StatefulWidget {
  const _DebugToolsSheet();

  @override
  State<_DebugToolsSheet> createState() => _DebugToolsSheetState();
}

class _DebugToolsSheetState extends State<_DebugToolsSheet> {
  _DebugSheetTab _tab = _DebugSheetTab.progression;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.36,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: ft.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: ft.cardBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ft.onSurfaceMuted.withValues(alpha: 0.28),
                        borderRadius:
                            BorderRadius.circular(Tokens.radiusProgress),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.bug_report_rounded,
                            size: 18, color: ft.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Debug tools',
                            style: TextStyle(
                              color: ft.onSurface,
                              fontSize: Tokens.fontSizeBody,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open full DevTools',
                          icon: Icon(Icons.open_in_full_rounded,
                              color: ft.onSurfaceMuted, size: 18),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DevToolsScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(Icons.close_rounded,
                              color: ft.onSurfaceMuted, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DebugSheetChip(
                            label: 'Progression',
                            icon: Icons.bolt_rounded,
                            selected: _tab == _DebugSheetTab.progression,
                            onTap: () => setState(
                                () => _tab = _DebugSheetTab.progression),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _DebugSheetChip(
                            label: 'Cosmetics',
                            icon: Icons.auto_awesome_rounded,
                            selected: _tab == _DebugSheetTab.cosmetics,
                            onTap: () => setState(
                                () => _tab = _DebugSheetTab.cosmetics),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPad + 16),
                  child: _DebugSheetContent(tab: _tab),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebugSheetChip extends StatelessWidget {
  const _DebugSheetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final color = selected ? ft.accent : ft.onSurfaceMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tokens.radiusProgress),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? ft.accent.withValues(alpha: 0.14)
              : ft.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(Tokens.radiusProgress),
          border: Border.all(
            color: selected
                ? ft.accent.withValues(alpha: 0.28)
                : ft.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: Tokens.fontSizeCaption,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugSheetContent extends StatelessWidget {
  const _DebugSheetContent({required this.tab});

  final _DebugSheetTab tab;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case _DebugSheetTab.progression:
        return const DevToolsProgressionEngineSection();
      case _DebugSheetTab.cosmetics:
        return const DevToolsCosmeticsSection();
    }
  }
}
