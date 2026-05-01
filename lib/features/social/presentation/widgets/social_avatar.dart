import 'package:flutter/material.dart';

import '../../../../shared/theme/design_tokens.dart';

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.color,
    this.radius,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Tokens.accent;
    final r = radius ?? size * 0.28;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: c.withValues(alpha: 0.18),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _Initials(initials: initials, color: c, size: size),
            )
          : _Initials(initials: initials, color: c, size: size),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(
      {required this.initials, required this.color, required this.size});
  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
