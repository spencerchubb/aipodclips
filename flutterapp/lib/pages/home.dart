import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
            padding: const EdgeInsets.only(left: 16, right: 16),
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
                  if (fetchVideoText != 'Fetch video') return;
                  setState(() => fetchVideoText = 'Fetching video... ⏳');
                  final originalUrl = _urlController.text;
                  final response = await callGCF({
                    'action': 'download',
                    'url': originalUrl,
                  });
                  final storageUrl = response['url'];
                  final title = response['title'];
                  FirebaseFirestore.instance.collection('videos').doc().set({
                    'createdAt': DateTime.now(),
                    'originalUrl': originalUrl,
                    'storageUrl': storageUrl,
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
          VideosList(),
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

class VideosList extends StatelessWidget {
  const VideosList({super.key});
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
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              final video = snapshot.data?.docs[index];
              final title = video?['title'] ?? 'Error :(';
              return InkWell(
                onTap: () {
                  if (video == null) return;
                  context.read<VideoNotifier>().setVideo(Video.fromDoc(video));
                  MyNavigator.pushNamed('/video');
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  // padding: const EdgeInsets.all
                  decoration: BoxDecoration(
                    border: index > 0
                        ? Border(top: BorderSide(color: Colors.grey))
                        : Border(),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
