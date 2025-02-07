import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late Snippet _snippet;
  late VideoNotifier _videoNotifier;

  @override
  void initState() {
    super.initState();
    _videoNotifier = context.read<VideoNotifier>();
    _snippet = _videoNotifier.video?.snippets[_videoNotifier.video?.currentSnippetIndex ?? 0] ?? Snippet(text: '');
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(_snippet.url!),
    );
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_videoNotifier.video?.title ?? ''),
      ),
      body: InkWell(
        onTap: () {
          _controller.play();
        },
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: 9 / 16,
                child: VideoPlayer(_controller),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}