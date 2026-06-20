import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omni_video_player/omni_video_player.dart';

class LessonPlayer extends StatefulWidget {
  final String videoId;

  const LessonPlayer({super.key, required this.videoId});

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  OmniPlaybackController? _controller;

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_update);
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

        // ✅ FIXED BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // correct GoRouter back navigation
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: OmniVideoPlayer(
              callbacks: VideoPlayerCallbacks(
                onControllerCreated: (controller) {
                  _controller?.removeListener(_update);
                  _controller = controller..addListener(_update);
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
