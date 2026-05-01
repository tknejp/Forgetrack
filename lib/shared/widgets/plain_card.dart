import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class PlainCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Domain? domain;

  const PlainCard({
    super.key,
    required this.child,
    this.padding,
    this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;

    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: domain != null
          ? domain!.cardDecoration()
          : BoxDecoration(
              color: ft.surfaceSubtle,
              borderRadius: BorderRadius.circular(Tokens.radiusCard),
              border: Border.all(color: ft.cardBorder),
            ),
      child: child,
    );
  }
}
