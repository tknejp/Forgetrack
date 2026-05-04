import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SpriteSheetLoop extends StatefulWidget {
  const SpriteSheetLoop({
    super.key,
    required this.assetPath,
    required this.columns,
    required this.rows,
    required this.frameCount,
    this.fps = 8,
    this.width = 160,
    this.height = 160,
  });

  final String assetPath;
  final int columns;
  final int rows;
  final int frameCount;
  final int fps;
  final double width;
  final double height;

  @override
  State<SpriteSheetLoop> createState() => _SpriteSheetLoopState();
}

class _SpriteSheetLoopState extends State<SpriteSheetLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (1000 * widget.frameCount / widget.fps).round(),
      ),
    )..repeat();

    _loadImage();
  }

  Future<void> _loadImage() async {
    final provider = AssetImage(widget.assetPath);
    final stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;

    listener = ImageStreamListener((info, _) {
      setState(() {
        _image = info.image;
      });
      stream.removeListener(listener);
    });

    stream.addListener(listener);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _currentFrame {
    return (_controller.value * widget.frameCount).floor() %
        widget.frameCount;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;

    if (image == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _SpriteSheetPainter(
            image: image,
            frame: _currentFrame,
            columns: widget.columns,
            rows: widget.rows,
          ),
        );
      },
    );
  }
}

class _SpriteSheetPainter extends CustomPainter {
  const _SpriteSheetPainter({
    required this.image,
    required this.frame,
    required this.columns,
    required this.rows,
  });

  final ui.Image image;
  final int frame;
  final int columns;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = image.width / columns;
    final frameHeight = image.height / rows;

    final column = frame % columns;
    final row = frame ~/ columns;

    final src = Rect.fromLTWH(
      column * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    final dst = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpriteSheetPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frame != frame ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows;
  }
}