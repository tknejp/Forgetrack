part of '../profile_settings_widgets.dart';

class ProfileExpandableTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String summary;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const ProfileExpandableTile({
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
  State<ProfileExpandableTile> createState() => _ProfileExpandableTileState();
}

class _ProfileExpandableTileState extends State<ProfileExpandableTile> {
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
                  _ProfileIconBadge(
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
                            color: FtTokens.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.summary,
                          style: tt.bodySmall?.copyWith(
                            color: FtTokens.onSurfaceMuted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FtTokens.onSurfaceMuted,
                    ),
                  ),
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
                      const ProfileTileDivider(indent: 0),
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
