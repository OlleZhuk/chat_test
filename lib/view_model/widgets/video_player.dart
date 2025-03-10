import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key, required this.filePath});

  final String filePath;

  @override
  VideoPlayerWidgetState createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() => setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
          _isPlaying = false;
        } else {
          _controller.play();
          _isPlaying = true;
        }
      });

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _openFullScreenVideo(BuildContext context, String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(child: VideoPlayerWidget(filePath: filePath)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (_showControls)
            Container(
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.red,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () =>
                        _openFullScreenVideo(context, widget.filePath),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
