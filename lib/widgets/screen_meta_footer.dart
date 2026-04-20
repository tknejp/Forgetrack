import 'package:flutter/material.dart';

class ScreenMetaFooter extends StatelessWidget {
  final String text;

  const ScreenMetaFooter({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.82),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
