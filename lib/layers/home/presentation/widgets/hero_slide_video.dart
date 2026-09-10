import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The video layer of a header slide.
///
/// Mounted only while its slide is the centre one, and disposed the moment it
/// is not — the same rule the website uses (`item.mediaType === "video" &&
/// isActive`). Seven slides each holding a live video decoder would be seven
/// decoders running behind a screen showing one of them, which on a mid-range
/// Android is the difference between a smooth carousel and a stuttering one.
///
/// It never draws a background. The poster is already painted underneath by
/// the carousel, so this stays transparent until the first frame is ready and
/// stays out of the way entirely if the video never loads.
class HeroSlideVideo extends StatefulWidget {
  final String url;

  const HeroSlideVideo({super.key, required this.url});

  @override
  State<HeroSlideVideo> createState() => _HeroSlideVideoState();
}

class _HeroSlideVideoState extends State<HeroSlideVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      // Muted, like every autoplaying video on the site. iOS refuses to
      // autoplay with sound at all, and a carousel that starts talking is a
      // carousel people close.
      await controller.setVolume(0);
      await controller.play();

      setState(() => _ready = true);
    } catch (_) {
      // A dead URL, an unsupported codec, no connection. The poster is
      // already on screen underneath; nothing more is owed.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) return const SizedBox.shrink();

    // FittedBox with the video's natural size inside a SizedBox.expand is the
    // equivalent of the site's `object-cover`: fill the card, crop the
    // overflow, never letterbox.
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
