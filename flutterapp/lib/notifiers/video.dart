import 'package:flutter/material.dart';
import '../models/video.dart';
class VideoNotifier extends ChangeNotifier {
  VideoNotifier({this.video});

  Video? video;

  setVideo(Video? video) {
    this.video = video;
    notifyListeners();
  }
}

