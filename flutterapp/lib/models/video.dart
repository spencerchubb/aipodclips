import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String id;
  final Timestamp createdAt;
  final String originalUrl;
  final String storageUrl;
  final String title;
  final Map<String, dynamic>? transcript;
  final String uid;

  Video({
    required this.id,
    required this.createdAt,
    required this.originalUrl,
    required this.storageUrl,
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
    String? title,
    Map<String, dynamic>? transcript,
    String? uid,
  }) {
    return Video(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      originalUrl: originalUrl ?? this.originalUrl,
      storageUrl: storageUrl ?? this.storageUrl,
      title: title ?? this.title,
      transcript: transcript ?? this.transcript,
      uid: uid ?? this.uid,
    );
  }
}