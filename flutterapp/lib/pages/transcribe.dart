import 'package:flutter/material.dart';
import 'package:flutterapp/gcf.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifiers/video.dart';
import '../navigator.dart';

class TranscribePage extends StatefulWidget {
  
  const TranscribePage({
    super.key,
  });

  @override
  State<TranscribePage> createState() => _TranscribePageState();
}

class _TranscribePageState extends State<TranscribePage> {
  final TextEditingController _promptController = TextEditingController();
  bool isTranscribing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transcribe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
                'Tip: If your podcast has jargon, use this prompt to help the AI spell it correctly!'),
            SizedBox(height: 8),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText:
                    'OpenAI makes technology like DALL·E, GPT-3, and ChatGPT with the hope of one day building an AGI system that benefits all of humanity.',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
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
                    'prompt': _promptController.text,
                  });
                  await FirebaseFirestore.instance.collection('videos').doc(video.id).update({
                    'transcript': response,
                  });
                  videoNotifier.setVideo(video.copyWith(transcript: response));
                  MyNavigator.pop();
                },
                child: Text(
                  isTranscribing ? 'Transcribing...' : 'Transcribe',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
