import 'package:flutter/material.dart';
import 'package:flutterapp/gcf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';
import '../navigator.dart';
import '../models/video.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<VideoNotifier>().video;
    if (video == null) {
      return const Scaffold(
        body: Center(child: Text('No video selected')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(video.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '1) Transcribe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              video.transcript == null
                  ? const NoTranscript()
                  : const YesTranscript(),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '2) Clips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              video.snippets.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final videoNotifier = context.read<VideoNotifier>();
                          final response = await callGCF({
                            'action': 'generate_snippets',
                            'transcript':
                                videoNotifier.video?.transcript?['text'],
                          });
                          FirebaseFirestore.instance
                              .collection('videos')
                              .doc(videoNotifier.video?.id)
                              .update({'snippets': response['snippets']});
                          final snippets =
                              (response['snippets'] as List<dynamic>)
                                  .map<Snippet>((e) => Snippet.fromJson(e))
                                  .toList();
                          videoNotifier.setVideo(videoNotifier.video
                              ?.copyWith(snippets: snippets));
                        },
                        child: const Text('Generate clips'),
                      ),
                    )
                  : Column(
                      children: video.snippets.map((snippet) {
                        return SnippetWidget(
                          video: video,
                          snippet: snippet,
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoTranscript extends StatefulWidget {
  const NoTranscript({super.key});

  @override
  State<NoTranscript> createState() => _NoTranscriptState();
}

class _NoTranscriptState extends State<NoTranscript> {
  bool isTranscribing = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          setState(() => isTranscribing = true);
          final videoNotifier = context.read<VideoNotifier>();
          final video = videoNotifier.video;
          if (video == null) {
            return;
          }
          final response = await callGCF({
            'action': 'transcribe',
            'video_id': video.id,
          });
          videoNotifier.setVideo(video.copyWith(transcript: response));
        },
        child: Text(isTranscribing ? 'Transcribing... ⏳' : 'Transcribe'),
      ),
    );
  }
}

class YesTranscript extends StatelessWidget {
  const YesTranscript({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<VideoNotifier>().video;

    return GestureDetector(
      onTap: () {
        MyNavigator.pushNamed('/transcript');
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          video?.transcript?['text'] ?? '',
          overflow: TextOverflow.ellipsis,
          maxLines: 4,
        ),
      ),
    );
  }
}

class SnippetWidget extends StatelessWidget {
  const SnippetWidget({super.key, required this.video, required this.snippet});

  final Video video;
  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: snippet.url == null
          ? ClipNotMade(video: video, snippet: snippet)
          : ClipMade(video: video, snippet: snippet),
    );
  }
}

class ClipMade extends StatefulWidget {
  const ClipMade({super.key, required this.video, required this.snippet});

  final Video video;
  final Snippet snippet;

  @override
  State<ClipMade> createState() => _ClipMadeState();
}

class _ClipMadeState extends State<ClipMade> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.snippet.url!),
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
    return InkWell(
      onTap: () {
        MyNavigator.pushNamed('/video_player');
      },
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
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
          SizedBox(width: 8),
          Expanded(
            child: Text(widget.snippet.text),
          ),
        ],
      ),
    );
  }
}

class ClipNotMade extends StatelessWidget {
  const ClipNotMade({super.key, required this.video, required this.snippet});

  final Video video;
  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final response = await callGCF({
          'action': 'create',
          'video_id': video.id,
          'snippet': snippet.text,
        });
        for (var i = 0; i < video.snippets.length; i++) {
          if (video.snippets[i].text == snippet.text) {
            video.snippets[i].id = response['snippet_id'];
          }
        }
        FirebaseFirestore.instance.collection('videos').doc(video.id).update({
          'snippets': video.snippets.map((e) => e.toJson()).toList(),
        });
      },
      child: Text(snippet.text),
    );
  }
}
