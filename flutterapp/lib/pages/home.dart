import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../gcf.dart';
import '../notifiers/video.dart';
import '../models/video.dart';
import '../navigator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool isDownloading = false;
  String fetchVideoText = 'Fetch video';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Column(
        children: [
          Padding(
            // Top padding avoids label being cut off
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: TextField(
              controller: _urlController,
              onChanged: (value) {
                setState(() => fetchVideoText = 'Fetch video');
              },
              decoration: const InputDecoration(
                labelText: 'Youtube URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_urlController.text.isEmpty) {
                    setState(() => fetchVideoText = 'Please enter a URL 🤗');
                    return;
                  }

                  if (fetchVideoText != 'Fetch video') return;
                  setState(() => fetchVideoText = 'Fetching video... ⏳');
                  final originalUrl = _urlController.text;
                  final videoDoc = FirebaseFirestore.instance.collection('videos').doc();
                  final response = await callGCF({
                    'action': 'download',
                    'url': originalUrl,
                    'video_id': videoDoc.id,
                  });

                  if (response['message'].contains('not a valid URL')) {
                    setState(() => fetchVideoText = 'Not a valid URL ❌');
                    return;
                  }

                  final title = response['title'];
                  await videoDoc.set({
                    'id': videoDoc.id,
                    'createdAt': DateTime.now(),
                    'originalUrl': originalUrl,
                    'title': title,
                    'uid': FirebaseAuth.instance.currentUser?.uid,
                  });
                  setState(() => fetchVideoText = 'Done fetching ✅');
                },
                child: Text(
                  fetchVideoText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Videos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          VideoList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

class VideoList extends StatelessWidget {
  const VideoList({super.key});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data?.docs[index];
              return VideoCard(index: index, doc: doc);
            },
          );
        },
      ),
    );
  }
}

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.index, required this.doc});
  final int index;
  final QueryDocumentSnapshot? doc;

  @override
  Widget build(BuildContext context) {
    final title = doc?['title'] ?? 'Error :(';
    return InkWell(
      onTap: () async {
        if (doc == null) return;

        final videoNotifier = context.read<VideoNotifier>();
        Video video = Video.fromDoc(doc!);
        String videoId = video.id;

        try {
          // Download transcript from firebase cloud storage
          final downloadUrl = await FirebaseStorage.instance
              .ref('transcripts/$videoId.json')
              .getDownloadURL();
          final transcript = await http.get(Uri.parse(downloadUrl));
          final transcriptData = jsonDecode(transcript.body);
          video = video.copyWith(transcript: transcriptData);
        } catch (e) {
          debugPrint(e.toString());
        }

        for (var i = 0; i < video.snippets.length; i++) {
          final snippet = video.snippets[i];
          if (snippet.id != null) {
            final downloadUrl = await FirebaseStorage.instance
                .ref('video_outputs/${snippet.id}.mp4')
                .getDownloadURL();
            video.snippets[i].url = downloadUrl;
          }
        }

        videoNotifier.setVideo(video);
        MyNavigator.pushNamed('/video');
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          border: index > 0
              ? Border(top: BorderSide(color: Colors.grey))
              : Border(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
            IconButton(
              onPressed: () {
                // Confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete video'),
                    content: Text(
                        'Are you sure you want to delete this video?\n\n$title'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('videos')
                              .doc(doc?.id)
                              .delete();
                          Navigator.pop(context);
                        },
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}
