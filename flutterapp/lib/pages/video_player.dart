import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';

// TODO: export and share video
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late Snippet _snippet;
  late VideoNotifier _videoNotifier;

  @override
  void initState() {
    super.initState();
    _videoNotifier = context.read<VideoNotifier>();
    _snippet = _videoNotifier.video?.snippets[_videoNotifier.video?.currentSnippetIndex ?? 0] ?? Snippet(text: '');
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(_snippet.url!),
    );
    
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 9/16, // Maintain your original aspect ratio
      autoPlay: true,
      looping: true,
      // You can add more options here like:
      // materialProgressColors: ChewieProgressColors(
      //   playedColor: Colors.red,
      //   handleColor: Colors.blue,
      //   backgroundColor: Colors.grey,
      //   bufferedColor: Colors.lightGreen,
      // ),
    );
    
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_videoNotifier.video?.title ?? ''),
      ),
      child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? Chewie(
              controller: _chewieController!,
            )
          : const Center(
              child: CupertinoActivityIndicator(),
            ),
    );
  }
}