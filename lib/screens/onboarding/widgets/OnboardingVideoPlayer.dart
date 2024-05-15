import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OnboardingVideoPlayer extends StatefulWidget {
  const OnboardingVideoPlayer({
    super.key,
    required this.asset,
  });

  final String asset;

  @override
  State<OnboardingVideoPlayer> createState() => _OnboardingVideoPlayerState();
}

class _OnboardingVideoPlayerState extends State<OnboardingVideoPlayer> {
  late final VideoPlayerController _controller;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.asset)
      ..setVolume(0)
      ..setLooping(true)
      ..initialize().then((_) {
        _initialized = true;
        if (mounted) {
          setState(() {});
        }
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? Flexible(
            child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller)),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}
