part of 'settings_widgets.dart';

class SettingsExpandableTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const SettingsExpandableTile({
    super.key,
    required this.icon,
    required this.label,
    required this.summary,
    required this.children,
    this.initiallyExpanded = false,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  State<SettingsExpandableTile> createState() => _SettingsExpandableTileState();
}

class _SettingsExpandableTileState extends State<SettingsExpandableTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _SettingsIconBadge(
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    backgroundColor: widget.iconBackgroundColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: tt.bodyLarge?.copyWith(
                            color: Tokens.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.summary,
                          style: tt.bodySmall?.copyWith(
                            color: Tokens.onSurfaceMuted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExpandChevron(expanded: _expanded),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Column(
                    children: [
                      const SettingsTileDivider(indent: 0),
                      ...widget.children,
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
