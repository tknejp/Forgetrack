import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Warms Flutter's in-memory imageCache (and cached_network_image's disk
/// cache) for a profile photo URL without needing a BuildContext.
///
/// Call as soon as the URL is known — typically from SocialProvider's
/// profile sync. By the time the hero avatar widget mounts on the home
/// screen, the bitmap is already decoded and Image() paints it on the
/// first frame instead of going through a one-frame placeholder swap
/// (the perceived "blink").
///
/// Best-effort: errors are swallowed (the avatar's errorBuilder still
/// handles broken URLs at render time).
void precacheProfilePhoto(String? url) {
  if (url == null || url.isEmpty) return;
  final provider = CachedNetworkImageProvider(url);
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, __) => stream.removeListener(listener),
    onError: (_, __) => stream.removeListener(listener),
  );
  stream.addListener(listener);
}
