import 'package:cloud_firestore/cloud_firestore.dart';

class Snippet {
  String? id;
  String text;
  String? url;

  Snippet({
    this.id,
    required this.text,
    this.url,
  });

  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(
      id: json['id'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }

  Snippet copyWith({
    String? id,
    String? text,
    String? url,
  }) {
    return Snippet(
      id: id ?? this.id,
      text: text ?? this.text,
      url: url ?? this.url,
    );
  }
}

class Video {
  final String id;
  final Timestamp createdAt;
  final String originalUrl;
  final List<Snippet> snippets;
  final String title;
  final String uid;
  final Map<String, dynamic>? transcript;
  final int currentSnippetIndex;

  Video({
    required this.id,
    required this.createdAt,
    required this.originalUrl,
    required this.snippets,
    required this.title,
    required this.uid,
    this.transcript,
    this.currentSnippetIndex = 0,
  });

  factory Video.fromDoc(QueryDocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      createdAt: json['createdAt'],
      originalUrl: json['originalUrl'],
      snippets: (json['snippets'] ?? [])
          .map<Snippet>((e) => Snippet.fromJson(e))
          .toList(),
      title: json['title'],
      uid: json['uid'],
    );
  }

  Video copyWith({
    String? id,
    Timestamp? createdAt,
    String? originalUrl,
    List<Snippet>? snippets,
    String? title,
    String? uid,
    Map<String, dynamic>? transcript,
    int? currentSnippetIndex,
  }) {
    return Video(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      originalUrl: originalUrl ?? this.originalUrl,
      snippets: snippets ?? this.snippets,
      title: title ?? this.title,
      uid: uid ?? this.uid,
      transcript: transcript ?? this.transcript,
      currentSnippetIndex: currentSnippetIndex ?? this.currentSnippetIndex,
    );
  }
}
