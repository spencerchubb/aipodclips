import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gcf.dart';
import '../navigator.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController(text: 'https://youtu.be/gYqs-wUKZsM?si=7uq0bLbld__lYSQK');
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
            // const SizedBox(height: double.infinity),
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
                    'uid': FirebaseAuth.instance.currentUser?.uid,
                    'originalUrl': originalUrl,
                    'storageUrl': storageUrl,
                    'title': title,
                    'createdAt': DateTime.now(),
                  });
                  MyNavigator.pushNamed('/prompt');
                },
                child: Text(
                  isDownloading ? 'Fetching video...' : 'Next',
                  style: TextStyle(fontSize: 16),
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
    _urlController.dispose();
    super.dispose();
  }
}
