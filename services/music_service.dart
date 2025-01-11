import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'dart:convert';
import '../lib/services/encrypted_storage_service.dart';

class MusicService {
  final EncryptedStorageService _encryptedStorage = EncryptedStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<List<Map<String, dynamic>>> getQuickPlaySongs({
    int offset = 0,
    int limit = 10,
  }) async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .range(offset, offset + limit - 1)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> _getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/songs';
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<String> _getSongFilePath(String songId) async {
    final downloadPath = await _getDownloadPath();
    return '$downloadPath/$songId.mp3';
  }

  Future<String> _getMetadataFilePath(String songId) async {
    final downloadPath = await _getDownloadPath();
    return '$downloadPath/$songId.json';
  }

  Future<bool> isSongDownloaded(String songId) async {
    await _encryptedStorage.init();
    return _encryptedStorage.isDownloaded('song_$songId');
  }

  Future<String?> _getDownloadUrl(String songId) async {
    try {
      // First try to get the URL from the songs table
      print('Fetching song data for ID: $songId');
      final songData = await Supabase.instance.client
          .from('songs')
          .select('audio_url')
          .eq('id', songId)
          .single();

      print('Song data from DB: $songData');

      if (songData != null && songData['audio_url'] != null) {
        print('Using direct audio_url: ${songData['audio_url']}');
        return songData['audio_url'];
      }

      // Try to get the public URL directly
      print('Attempting to get public URL from storage');
      final publicUrl = await Supabase.instance.client.storage
          .from('songs')
          .getPublicUrl('$songId.mp3');
      
      print('Generated public URL: $publicUrl');
      
      // If we got a public URL, use it
      if (publicUrl.isNotEmpty) {
        return publicUrl;
      }

      // Last resort - try signed URL
      print('Attempting to create signed URL');
      final signedUrl = await Supabase.instance.client.storage
          .from('songs')
          .createSignedUrl('$songId.mp3', 3600);
      
      print('Generated signed URL: $signedUrl');
      return signedUrl;

    } catch (e, stackTrace) {
      print('Detailed error getting download URL:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<int>?> _downloadFromStorage(String songId) async {
    try {
      print('Attempting direct storage download for song: $songId');
      final bytes = await Supabase.instance.client.storage
          .from('songs')
          .download('$songId.mp3');
      print('Successfully downloaded bytes from storage');
      return bytes;
    } catch (e) {
      print('Storage download error: $e');
      return null;
    }
  }

  Future<void> downloadSong(Map<String, dynamic> song) async {
    final songId = song['id'];

    try {
      print('Starting download for song ID: $songId');
      await _encryptedStorage.init();

      // Try direct storage download first
      final bytes = await _downloadFromStorage(songId);
      if (bytes == null) {
        throw Exception('Could not download song from storage');
      }

      // Save encrypted audio and metadata
      await _encryptedStorage.encryptAndSave(
        bytes,
        'song_$songId',
      );

      // Save metadata
      final metadataFileName = 'metadata_$songId';
      await _encryptedStorage.encryptAndSave(
        utf8.encode(json.encode(song)),
        metadataFileName,
      );

      print('Successfully downloaded and encrypted song: $songId');
    } catch (e, stackTrace) {
      print('Detailed download error:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to download song: $e');
    }
  }

  Future<Map<String, dynamic>?> getDownloadedSongMetadata(String songId) async {
    try {
      await _encryptedStorage.init();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/metadata_$songId.enc';
      final decryptedData = await _encryptedStorage.decryptFile(filePath);
      return json.decode(utf8.decode(decryptedData));
    } catch (e) {
      print('Error reading song metadata: $e');
      return null;
    }
  }

  Future<String?> getLocalSongPath(String songId) async {
    try {
      final audioFile = File(await _getSongFilePath(songId));
      if (await audioFile.exists()) {
        return audioFile.path;
      }
    } catch (e) {
      print('Error getting local song path: $e');
    }
    return null;
  }

  Future<List<int>?> getDecryptedSongData(String songId) async {
    try {
      await _encryptedStorage.init();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/song_$songId.enc';
      return await _encryptedStorage.decryptFile(filePath);
    } catch (e) {
      print('Error decrypting song data: $e');
      return null;
    }
  }

  Future<void> playSong(String url, {
    Map<String, dynamic>? currentSong,
    List<Map<String, dynamic>>? subsequentSongs,
  }) async {
    if (currentSong != null && currentSong['id'] != null) {
      try {
        // Check if song is downloaded
        final decryptedData = await getDecryptedSongData(currentSong['id']);
        if (decryptedData != null) {
          // Create a temporary file with decrypted data for playback
          final directory = await getTemporaryDirectory();
          final tempFile = File('${directory.path}/temp_${currentSong['id']}.mp3');
          await tempFile.writeAsBytes(decryptedData);

          // Play the decrypted local file
          await _audioPlayer.setFilePath(tempFile.path);
          await _audioPlayer.play();

          // Delete temp file after playback starts
          tempFile.delete().catchError((e) => print('Error deleting temp file: $e'));
          return;
        }
      } catch (e) {
        print('Error playing local file: $e');
      }
    }

    // Fall back to streaming if no local file exists or if there's an error
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      print('Error streaming song: $e');
      throw Exception('Failed to play song: $e');
    }
  }
}