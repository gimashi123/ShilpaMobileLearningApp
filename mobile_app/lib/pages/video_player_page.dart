import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile_app/services/progress_api.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? lessonId;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.lessonId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('Opening VideoPlayerPage with URL: ${widget.videoUrl}');

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
      });
      _controller.play();
    }).catchError((e) {
      print('VIDEO INIT ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    });

    _controller.addListener(() {
      if (_controller.value.hasError) {
        print('VIDEO PLAYER ERROR: ${_controller.value.errorDescription}');
        if (mounted) {
          setState(() {
            _error = _controller.value.errorDescription;
          });
        }
      }
      
      // Auto-complete when video finishes
      if (_initialized && 
          _controller.value.position >= _controller.value.duration && 
          widget.lessonId != null) {
        _markAsComplete();
      }
    });
  }

  bool _completedSent = false;
  void _markAsComplete() async {
    if (_completedSent) return;
    _completedSent = true;
    print("Video finished, marking lesson ${widget.lessonId} as complete...");
    await ProgressApi.completeLesson(widget.lessonId!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _error != null
            ? Text(
                'Video error:\n$_error',
                textAlign: TextAlign.center,
              )
            : !_initialized
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _initialized && _error == null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
