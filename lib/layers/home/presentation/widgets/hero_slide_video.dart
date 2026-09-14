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
///
/// HOW THIS BURNED 6GB OF EGRESS IN TWO DAYS
///
/// It used to `setLooping(true)` and play, with nothing ever stopping it.
/// `VideoPlayerController.networkUrl` does not cache, so every loop re-fetched
/// the file from Supabase Storage. A phone left on the Home screen — which is
/// what a phone does while you work on the app all day — streamed the same
/// video continuously for as long as it was there, and the project's entire
/// egress quota went with it.
///
/// So now: it plays ONCE, it stops when the app is backgrounded, and it never
/// restarts on its own. The carousel moves to the next slide every few seconds
/// anyway, which is what makes a single play the right length rather than a
/// compromise.
class HeroSlideVideo extends StatefulWidget {
  final String url;

  const HeroSlideVideo({super.key, required this.url});

  @override
  State<HeroSlideVideo> createState() => _HeroSlideVideoState();
}

class _HeroSlideVideoState extends State<HeroSlideVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // So the video can be paused when the app leaves the foreground. Without
    // it, a backgrounded app on Android keeps the player running and keeps
    // pulling bytes for a picture nobody is looking at.
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      // NOT looping. See the class doc — this is the line that cost the quota.
      // One pass is all the slide is on screen for.
      await controller.setLooping(false);

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.resumed) {
      // Deliberately does NOT resume playback. Coming back to the app should
      // not start a fresh download of a video the person has already seen —
      // the carousel will move on shortly, and the poster underneath is a
      // perfectly good still.
      return;
    }

    controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
