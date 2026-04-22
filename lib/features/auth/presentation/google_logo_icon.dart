import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const googleLogoAssetPath = 'assets/icons/google/google_logo.svg';

class GoogleLogoIcon extends StatefulWidget {
  final double size;
  final Widget? fallback;
  final String? semanticsLabel;

  const GoogleLogoIcon({
    super.key,
    required this.size,
    this.fallback,
    this.semanticsLabel,
  });

  static Future<String?> _loadSvg() async {
    try {
      return await rootBundle.loadString(googleLogoAssetPath);
    } catch (_) {
      return null;
    }
  }

  @override
  State<GoogleLogoIcon> createState() => _GoogleLogoIconState();
}

class _GoogleLogoIconState extends State<GoogleLogoIcon> {
  late final Future<String?> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = GoogleLogoIcon._loadSvg();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<String?>(
        future: _svgFuture,
        builder: (context, snapshot) {
          final svg = snapshot.data;
          if (svg == null || snapshot.hasError) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: widget.fallback ??
                  Icon(
                    Icons.login_rounded,
                    size: widget.size,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            );
          }

          return SvgPicture.string(
            svg,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            semanticsLabel: widget.semanticsLabel,
          );
        },
      ),
    );
  }
}
