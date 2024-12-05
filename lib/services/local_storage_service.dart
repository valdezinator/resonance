import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> saveSong(String id, List<int> bytes) async {
    // Implementation for saving song bytes
  }

  Future<void> addToDownloadedSongs(Map<String, dynamic> song) async {
    final prefs = await _prefs;
    final songs = prefs.getStringList('downloaded_songs') ?? [];
    songs.add(song['id']);
    await prefs.setStringList('downloaded_songs', songs);
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    final prefs = await _prefs;
    return prefs.getStringList('downloaded_songs')?.map((id) => {'id': id}).toList() ?? [];
  }
} 