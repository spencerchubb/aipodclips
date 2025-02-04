import 'package:flutter/material.dart';
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
          ],
        ),
      ),
    );
  }
}

class NoTranscript extends StatelessWidget {
  const NoTranscript({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
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
          video?.transcript ?? '',
          overflow: TextOverflow.ellipsis,
          maxLines: 4,
        ),
      ),
    );
  }
}
