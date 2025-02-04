import 'package:flutter/material.dart';
import 'package:flutterapp/gcf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';
import '../navigator.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                '2) Snippets',
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
                          'action': 'choose_snippets',
                          'transcript':
                              videoNotifier.video?.transcript?['text'],
                        });
                        FirebaseFirestore.instance
                            .collection('videos')
                            .doc(videoNotifier.video?.id)
                            .update({'snippets': response['snippets']});
                        videoNotifier.video
                            ?.copyWith(snippets: response['snippets']);
                      },
                      child: const Text('Choose snippets'),
                    ),
                  )
                : Column(
                    children: video.snippets.map((e) => Text(e)).toList(),
                  )
          ],
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
            'url': video.storageUrl,
          });
          await FirebaseFirestore.instance
              .collection('videos')
              .doc(video.id)
              .update({
            'transcript': response,
          });
          videoNotifier.setVideo(video.copyWith(transcript: response));
        },
        child: const Text('Transcribe video'),
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
