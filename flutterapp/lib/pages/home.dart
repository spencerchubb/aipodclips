import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../gcf.dart';
import '../navigator.dart';
import '../notifiers/video.dart';
import '../models/video.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController(
      text: 'https://youtu.be/gYqs-wUKZsM?si=7uq0bLbld__lYSQK');
  bool isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Youtube URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() => isDownloading = true);
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
                  MyNavigator.pushNamed('/prompt');
                },
                child: Text(
                  isDownloading ? 'Fetching video...' : 'Next',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Videos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            VideosList(),
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              final video = snapshot.data?.docs[index].data();
              final title = video?['title'] ?? 'Error :(';
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  onPressed: () {
                    if (video == null) return;
                    context
                        .read<VideoNotifier>()
                        .setVideo(Video.fromJson(video));
                    MyNavigator.pushNamed('/video');
                  },
                  child: Text(title),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
