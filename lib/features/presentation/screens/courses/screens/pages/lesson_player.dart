import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LessonPlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const LessonPlayer({super.key, required this.videoId, required this.title});

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  double _currentSpeed = 1.0;

  static const List<double> _speedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ..._speedOptions.map((speed) {
                return ListTile(
                  title: Text('${speed}x'),
                  trailing: _currentSpeed == speed
                      ? const Icon(Icons.check, color: Colors.red)
                      : null,
                  onTap: () {
                    _controller.setPlaybackRate(speed);
                    setState(() => _currentSpeed = speed);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        onReady: () {
          setState(() => _isPlayerReady = true);
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text("${widget.title}"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.pop();
              },
            ),
          ),
          body: Column(
            children: [
              player,

              if (!_isPlayerReady)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isPlayerReady
                          ? () => _controller.pause()
                          : null,
                      child: const Icon(Icons.pause),
                    ),
                    ElevatedButton(
                      onPressed: _isPlayerReady
                          ? () => _controller.play()
                          : null,
                      child: const Icon(Icons.play_arrow),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isPlayerReady ? _showSpeedPicker : null,
                      icon: const Icon(Icons.speed),
                      label: Text('${_currentSpeed}x'),
                    ),
                    ElevatedButton(
                      onPressed: _isPlayerReady
                          ? () => _controller.toggleFullScreenMode()
                          : null,
                      child: const Icon(Icons.fullscreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
