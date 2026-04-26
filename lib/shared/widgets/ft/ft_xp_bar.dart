import 'package:flutter/material.dart';

import '../../theme/ft_design_tokens.dart';
import 'ft_progress_bar.dart';

class FtXpBar extends StatefulWidget {
  final int level;
  final String title;
  final int xp;
  final int xpMax;
  final Widget? expandedChild;
  final bool initiallyExpanded;

  const FtXpBar({
    super.key,
    required this.level,
    required this.title,
    required this.xp,
    required this.xpMax,
    this.expandedChild,
    this.initiallyExpanded = false,
  });

  @override
  State<FtXpBar> createState() => _FtXpBarState();
}

class _FtXpBarState extends State<FtXpBar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isExpandable = widget.expandedChild != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isExpandable
                ? () => setState(() {
                      _expanded = !_expanded;
                    })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FtTokens.accent,
                          FtTokens.accent.withValues(alpha: 0.53),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.level}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LEVEL ${widget.level} · ${widget.title.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: FtTokens.fontSizeMicro,
                                fontWeight: FontWeight.w700,
                                color: FtTokens.accent,
                                letterSpacing: 0.9,
                              ),
                            ),
                            Text(
                              '${widget.xp} / ${widget.xpMax} XP',
                              style: const TextStyle(
                                fontSize: FtTokens.fontSizeMicro,
                                color: FtTokens.onSurfaceFaint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FtProgressBar(
                          value: widget.xp / widget.xpMax,
                          color: FtTokens.accent,
                          glow: FtTokens.accentGlow,
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded && widget.expandedChild != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(
                        children: [
                          const Divider(
                            color: Color(0x12FFFFFF),
                            thickness: 1,
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          widget.expandedChild!,
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
