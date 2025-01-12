import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';  // Add this import
import 'dart:io';  // Add this import

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

  Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is Map) {
      await prefs.setString(key, json.encode(value));
    } else if (value is List) {
      await prefs.setString(key, json.encode(value));
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  Future<dynamic> getData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key);
    if (value is String) {
      try {
        return json.decode(value);
      } catch (e) {
        return value;
      }
    }
    return value;
  }

  Future<void> removeData(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  Future<void> saveAlbumMetadata(String albumId, Map<String, dynamic> albumData) async {
    final prefs = await _prefs;
    final key = 'album_$albumId';
    await saveData(key, albumData);
  }

  Future<Map<String, dynamic>?> getAlbumMetadata(String albumId) async {
    final prefs = await _prefs;
    final key = 'album_$albumId';
    return await getData(key);
  }

  Future<List<String>> getDownloadedAlbumIds() async {
    final prefs = await _prefs;
    return prefs.getStringList('downloaded_album_ids') ?? [];
  }

  Future<void> addDownloadedAlbumId(String albumId) async {
    final prefs = await _prefs;
    final ids = await getDownloadedAlbumIds();
    if (!ids.contains(albumId)) {
      ids.add(albumId);
      await prefs.setStringList('downloaded_album_ids', ids);
    }
  }

  Future<bool> isDownloaded(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.mp3');
      return await file.exists();
    } catch (e) {
      print('Error checking if file is downloaded: $e');
      return false;
    }
  }
}