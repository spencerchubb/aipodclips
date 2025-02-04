import 'package:cloud_firestore/cloud_firestore.dart';

List<String> castDynamicList(List<dynamic> list) {
  return list.map((e) => e.toString()).toList();
}

class Video {
  final String id;
  final Timestamp createdAt;
  final String originalUrl;
  final String storageUrl;
  final List<String> snippets;
  final String title;
  final Map<String, dynamic>? transcript;
  final String uid;

  Video({
    required this.id,
    required this.createdAt,
    required this.originalUrl,
    required this.storageUrl,
    required this.snippets,
    required this.title,
    this.transcript,
    required this.uid,
  });

  factory Video.fromDoc(QueryDocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      createdAt: json['createdAt'],
      originalUrl: json['originalUrl'],
      storageUrl: json['storageUrl'],
      snippets: castDynamicList(json['snippets'] ?? []),
      title: json['title'],
      transcript: json['transcript'],
      uid: json['uid'],
    );
  }

  Video copyWith({
    String? id,
    Timestamp? createdAt,
    String? originalUrl,
    String? storageUrl,
    List<String>? snippets,
    String? title,
    Map<String, dynamic>? transcript,
    String? uid,
  }) {
    return Video(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      originalUrl: originalUrl ?? this.originalUrl,
      storageUrl: storageUrl ?? this.storageUrl,
      snippets: snippets ?? this.snippets,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      uid: uid ?? this.uid,
    );
  }
}