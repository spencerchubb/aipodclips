import 'package:flutter/material.dart';
import 'package:flutterapp/gcf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';
import '../navigator.dart';
import '../models/video.dart';
import 'package:video_player/video_player.dart';
import '../widgets/custom_button.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  List<Widget> clips(BuildContext context, Video video) {
    if (video.transcriptText == null) {
      return [];
    }
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Clips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 10),
      video.clips.isEmpty
          ? SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: () async {
                  final videoNotifier = context.read<VideoNotifier>();
                  final response = await callGCF({
                    'action': 'generate_snippets',
                    'transcript': videoNotifier.video?.transcriptText,
                  });
                  FirebaseFirestore.instance
                      .collection('videos')
                      .doc(videoNotifier.video?.id)
                      .update({'clips': response['clips']});
                  final clips = (response['clips'] as List<dynamic>)
                      .map<Snippet>((e) => Snippet.fromJson(e))
                      .toList();
                  videoNotifier
                      .setVideo(videoNotifier.video?.copyWith(clips: clips));
                },
                text: 'Generate clips',
              ),
            )
          : Column(
              children: video.clips.map((clip) {
                return SnippetWidget(
                  video: video,
                  snippet: clip,
                );
              }).toList(),
            ),
    ];
  }

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
                  'Transcript',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              video.transcriptText == null
                  ? const NoTranscript()
                  : const YesTranscript(),
              const SizedBox(height: 30),
              ...clips(context, video),
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
      child: CustomButton(
        onPressed: () async {
          setState(() => isTranscribing = true);
          final videoNotifier = context.read<VideoNotifier>();
          Video? video = videoNotifier.video;
          if (video == null) {
            return;
          }

          final response = await callGCF({
            'action': 'transcribe',
            'video_id': video.id,
          });
          FirebaseFirestore.instance.collection('videos').doc(video.id).update({
            'transcriptText': response['text'],
          });
          video = video.copyWith(transcriptText: response['text']);
          videoNotifier.setVideo(video);

          final titleResponse = await callGCF({
            'action': 'generate_title',
            'text': response['text'],
          });
          FirebaseFirestore.instance.collection('videos').doc(video.id).update({
            'title': titleResponse['title'],
          });
          video = video.copyWith(title: titleResponse['title']);
          videoNotifier.setVideo(video);
        },
        text: isTranscribing ? 'Transcribing... ⏳' : 'Transcribe',
      ),
    );
  }
}

class YesTranscript extends StatelessWidget {
  const YesTranscript({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<VideoNotifier>().video;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          MyNavigator.pushNamed('/transcript');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video?.transcriptText ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Read more',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: snippet.url == null
            ? ClipNotMade(video: video, snippet: snippet)
            : ClipMade(video: video, snippet: snippet),
      ),
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
    final videoWidth = MediaQuery.of(context).size.width * 0.3;
    return InkWell(
      onTap: () {
        final videoNotifier = context.read<VideoNotifier>();
        videoNotifier.setVideo(videoNotifier.video?.copyWith(
          currentSnippetIndex: widget.video.clips.indexOf(widget.snippet),
        ));
        MyNavigator.pushNamed('/video_player');
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: videoWidth,
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: 9 / 16,
                      child: VideoPlayer(_controller),
                    );
                  }
                  return const AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: videoWidth * 16 / 9,
              child: Text(
                widget.snippet.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
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
    final videoWidth = MediaQuery.of(context).size.width * 0.3;
    return InkWell(
      onTap: () async {
        final response = await callGCF({
          'action': 'create',
          'video_id': video.id,
          'snippet': snippet.text,
        });
        for (var i = 0; i < video.clips.length; i++) {
          if (video.clips[i].text == snippet.text) {
            video.clips[i].id = response['clip_id'];
          }
        }
        FirebaseFirestore.instance.collection('videos').doc(video.id).update({
          'clips': video.clips.map((e) => e.toJson()).toList(),
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.add_circle_outline,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: videoWidth * 16 / 9,
              child: Text(
                snippet.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
