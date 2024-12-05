import 'package:flutter/foundation.dart';

class CurrentSongState extends ChangeNotifier {
  Map<String, dynamic>? _currentSong;

  Map<String, dynamic>? get currentSong => _currentSong;

  void setCurrentSong(Map<String, dynamic>? song) {
    _currentSong = song;
    notifyListeners();
  }
} 