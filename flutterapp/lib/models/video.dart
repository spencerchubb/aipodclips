import 'package:cloud_firestore/cloud_firestore.dart';

List<String> castDynamicList(List<dynamic> list) {
  return list.map((e) => e.toString()).toList();
}

class Video {
  final String id;
  final Timestamp createdAt;
  final String originalUrl;
  final List<dynamic> snippets;
  final String title;
  final String uid;
  final Map<String, dynamic>? transcript;

  Video({
    required this.id,
    required this.createdAt,
    required this.originalUrl,
    required this.snippets,
    required this.title,
    required this.uid,
    this.transcript,
  });

  factory Video.fromDoc(QueryDocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      createdAt: json['createdAt'],
      originalUrl: json['originalUrl'],
      snippets: castDynamicList(json['snippets'] ?? []),
      title: json['title'],
      uid: json['uid'],
    );
  }

  Video copyWith({
    String? id,
    Timestamp? createdAt,
    String? originalUrl,
    List<String>? snippets,
    String? title,
    String? uid,
    Map<String, dynamic>? transcript,
  }) {
    return Video(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      originalUrl: originalUrl ?? this.originalUrl,
      snippets: snippets ?? this.snippets,
      title: title ?? this.title,
      uid: uid ?? this.uid,
      transcript: transcript ?? this.transcript,
    );
  }
}