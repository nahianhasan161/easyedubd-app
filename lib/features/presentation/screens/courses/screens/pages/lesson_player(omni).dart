import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omni_video_player/omni_video_player.dart';

class OmniLessonPlayer extends StatefulWidget {
  final String videoId;

  const OmniLessonPlayer({super.key, required this.videoId});

  @override
  State<OmniLessonPlayer> createState() => _OmniLessonPlayerState();
}

class _OmniLessonPlayerState extends State<OmniLessonPlayer> {
  OmniPlaybackController? _controller;
  bool _isDisposing = false; // 🔥 guards against late callbacks after dispose

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _disposeCurrentController() {
    if (_controller != null) {
      _controller!.removeListener(_update);
      _controller!.dispose(); // 🔥 always dispose before dropping the reference
      _controller = null;
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _disposeCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoUrl = Uri.parse(
      'https://www.youtube.com/watch?v=${widget.videoId}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: OmniVideoPlayer(
              key: ValueKey(widget.videoId),
              callbacks: VideoPlayerCallbacks(
                onControllerCreated: (controller) {
                  // 🔥 Guard: if this widget is mid-dispose, immediately
                  // dispose the newly created controller instead of keeping it.
                  if (_isDisposing || !mounted) {
                    controller.dispose();
                    return;
                  }

                  // 🔥 Dispose the OLD controller fully before swapping in the new one.
                  _disposeCurrentController();

                  _controller = controller..addListener(_update);

                  // Trigger a rebuild so the Play/Pause button shows up
                  // now that _controller is non-null.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                },
                onFullScreenToggled: (isFullScreen) {},
                onOverlayControlsVisibilityChanged: (areVisible) {},
                onCenterControlsVisibilityChanged: (areVisible) {},
                onMuteToggled: (isMute) {},
                onSeekStart: (pos) {},
                onSeekEnd: (pos) {},
                onSeekRequest: (target) => true,
                onFinished: () {},
                onReplay: () {},
              ),

              configuration: VideoPlayerConfiguration(
                videoSourceConfiguration:
                    VideoSourceConfiguration.youtube(
                      videoUrl: videoUrl,
                      preferredQualities: const [
                        OmniVideoQuality.high720,
                        OmniVideoQuality.low144,
                      ],
                      availableQualities: const [
                        OmniVideoQuality.high1080,
                        OmniVideoQuality.high720,
                        OmniVideoQuality.medium480,
                        OmniVideoQuality.medium360,
                        OmniVideoQuality.low144,
                      ],
                      enableYoutubeWebViewFallback: true,
                      forceYoutubeWebViewOnly: false,
                    ).copyWith(
                      autoPlay: false,
                      initialPosition: Duration.zero,
                      initialVolume: 1.0,
                      initialPlaybackSpeed: 1.0,
                      availablePlaybackSpeed: const [0.5, 1.0, 1.25, 1.5, 2.0],
                      autoMuteOnStart: false,
                      allowSeeking: true,
                      synchronizeMuteAcrossPlayers: true,
                      timeoutDuration: const Duration(seconds: 30),
                    ),
                playerTheme: OmniVideoPlayerThemeData().copyWith(
                  icons: VideoPlayerIconTheme().copyWith(
                    error: Icons.warning,
                    playbackSpeedButton: Icons.speed,
                  ),
                  backdrop: VideoPlayerBackdropTheme().copyWith(
                    backgroundColor: Colors.white,
                    alpha: 25,
                  ),
                ),
                playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
                  showSeekBar: true,
                  showCurrentTime: true,
                  showDurationTime: true,
                  showRemainingTime: true,
                  showLiveIndicator: true,
                  showLoadingWidget: true,
                  showErrorPlaceholder: true,
                  showReplayButton: true,
                  showThumbnailAtStart: true,
                  showVideoBottomControlsBar: true,
                  showFullScreenButton: true,
                  showPlaybackSpeedButton: true,
                  showMuteUnMuteButton: true,
                  showPlayPauseReplayButton: true,
                  useSafeAreaForBottomControls: true,
                  enableForwardGesture: true,
                  enableBackwardGesture: true,
                  enableExitFullscreenOnVerticalSwipe: true,
                  enableOrientationLock: true,
                  controlsPersistenceDuration: const Duration(seconds: 3),
                  fitVideoToBounds: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.all(16),
            child: _controller == null
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: () {
                      _controller!.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                    },
                    icon: Icon(
                      _controller!.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(_controller!.isPlaying ? 'Pause' : 'Play'),
                  ),
          ),
        ],
      ),
    );
  }
}
