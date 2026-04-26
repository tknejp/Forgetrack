import 'package:flutter/material.dart';
import '../../theme/ft_design_tokens.dart';

class FtPlainCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final FtDomain? domain;

  const FtPlainCard({
    super.key,
    required this.child,
    this.padding,
    this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: domain != null
          ? domain!.cardDecoration()
          : BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(FtTokens.radiusCard),
              border: Border.all(color: FtTokens.cardBorder),
            ),
      child: child,
    );
  }
}
