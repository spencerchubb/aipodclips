import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../gcf.dart';
import '../notifiers/video.dart';
import '../models/video.dart';
import '../navigator.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Your Videos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const VideoList(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.video,
                    allowMultiple: false,
                  );

                  if (result != null) {
                    File file = File(result.files.single.path!);
                    // Upload video to firebase storage
                    final videoDoc =
                        FirebaseFirestore.instance.collection('videos').doc();
                    debugPrint('Uploading video to firebase storage');
                    await FirebaseStorage.instance
                        .ref('video_inputs')
                        .child('${videoDoc.id}.mp4')
                        .putFile(file);
                    debugPrint('Saving video data to firestore');
                    await videoDoc.set({
                      'id': videoDoc.id,
                      'createdAt': DateTime.now(),
                      'originalUrl': file.path,
                      'title': videoDoc.id,
                      'uid': FirebaseAuth.instance.currentUser?.uid,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Upload New Video',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
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
