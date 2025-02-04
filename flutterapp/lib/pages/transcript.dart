import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/video.dart';

class TranscriptPage extends StatelessWidget {
  const TranscriptPage({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<VideoNotifier>().video;
    return Scaffold(
      appBar: AppBar(title: const Text('Transcript')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
        child: Text(video?.transcript?['text'] ?? ''),
      ),
    );
  }
}
