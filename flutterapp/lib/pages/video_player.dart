import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    print('current snippet index: ${_videoNotifier.video?.currentSnippetIndex}');
    _snippet = _videoNotifier
            .video?.clips[_videoNotifier.video?.currentSnippetIndex ?? 0] ??
        Snippet(text: '');
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    debugPrint('snippet url: ${_snippet.url}');
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(_snippet.url!),
    );

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 9 / 16,
      autoPlay: true,
      looping: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> handleCopy(String url) async {
    Clipboard.setData(ClipboardData(text: url));
    Fluttertoast.showToast(
      msg: 'Copied URL ✅',
      gravity: ToastGravity.CENTER,
      backgroundColor: CupertinoColors.darkBackgroundGray,
      textColor: CupertinoColors.systemGrey4,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool videoInited = _chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.darkBackgroundGray,
      child: DefaultTextStyle(
        style: const TextStyle(), // Prevents yellow underline
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.chevron_left,
                      size: 28,
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _videoNotifier.video?.title ?? '',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey4,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () => handleCopy(_snippet.url!),
                    child: const Icon(
                      Icons.copy,
                      size: 28,
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: videoInited
                    ? Chewie(
                        controller: _chewieController!,
                      )
                    : const Center(
                        child: CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
