import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'encrypted_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';


class MusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _supabase = Supabase.instance.client;
  late ConcatenatingAudioSource _playlist;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleEnabled = false;
  final _localStorageService = LocalStorageService();
  final _queueController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _currentSongController =
      StreamController<Map<String, dynamic>>.broadcast();
  final EncryptedStorageService _encryptedStorage = EncryptedStorageService();

  static const String ALBUMS_CACHE_KEY = 'albums_cache';
  static const String ARTISTS_CACHE_KEY = 'artists_cache';
  static const String SONGS_CACHE_KEY = 'songs_cache';

  MusicService() {
    _playlist = ConcatenatingAudioSource(children: []);
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.setPreferredPeakBitRate(320000);
    _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(true);

    // Listen to current playing audio
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _playlist.sequence.isNotEmpty) {
        final currentSong =
            _playlist.sequence[index].tag as Map<String, dynamic>;
        _currentSongController.add(currentSong);
      }
    });

    // Keep the completion listener for queue management
    _audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        try {
          await playNext();
        } catch (e) {
          print('Error during auto-play: $e');
        }
      }
    });
  }

  Future<void> init() async {
    await _encryptedStorage.init();
    await _initAudioPlayer();
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Future<Duration> get position async => await _audioPlayer.position;

  Future<List<Map<String, dynamic>>> getQuickPlaySongs({
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('quick_play_songs')
          .select()
          .range(offset, offset + limit - 1)
          .order('created_at');

      if (response == null) {
        throw Exception('No data received from Supabase');
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching songs: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAlbums() async {
    try {
      // Try to fetch from network
      final response = await _supabase
          .from('albums')
          .select()
          .eq('category', 'hits')
          .order('created_at');

      final albums = List<Map<String, dynamic>>.from(response as List);
      await _localStorageService.saveData(ALBUMS_CACHE_KEY, albums);
      return albums;
    } catch (e) {
      print('Error fetching albums from network: $e');
      
      // Try to get cached albums first
      final cachedAlbums = await _localStorageService.getData(ALBUMS_CACHE_KEY);
      if (cachedAlbums != null) {
        return List<Map<String, dynamic>>.from(cachedAlbums);
      }
      
      // If no cached albums, return downloaded albums
      return await getDownloadedAlbums();
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendedArtists() async {
    try {
      final response = await _supabase
          .from('recommended_artists')
          .select()
          .order('created_at');

      if (response == null) {
        throw Exception('No data received from Supabase');
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching recommended artists: $e');
      rethrow;
    }
  }

  Future<void> playSong(String url,
      {Map<String, dynamic>? currentSong,
      Map<String, dynamic>? nextSong,
      List<Map<String, dynamic>>? subsequentSongs}) async {
    if (currentSong != null && currentSong['id'] != null) {
      try {
        final metadata = await _localStorageService.getData('metadata_${currentSong['id']}');
        if (metadata != null && metadata['secure_file'] != null) {
          final filePath = await _getSecureFilePath(metadata['secure_file']);
          final file = File(filePath);
          
          if (await file.exists()) {
            // Decrypt the file
            final encrypted = await file.readAsBytes();
            final decrypted = _xorEncrypt(encrypted, currentSong['id']); // XOR is its own inverse

            // Create temporary file for playback
            final tempFile = await File('${(await getTemporaryDirectory()).path}/temp_${currentSong['id']}.mp3');
            await tempFile.writeAsBytes(decrypted);

            // Create playlist and play
            final playlist = ConcatenatingAudioSource(children: [
              AudioSource.file(tempFile.path, tag: currentSong),
            ]);

            // Add subsequent songs...
            if (subsequentSongs != null) {
              for (var song in subsequentSongs) {
                if (song['audio_url'] != null) {
                  playlist.add(AudioSource.uri(
                    Uri.parse(song['audio_url']),
                    tag: song,
                  ));
                }
              }
            }

            await _audioPlayer.setAudioSource(playlist);
            _playlist = playlist;
            await _audioPlayer.play();
            _updateQueueStream();

            // Delete temp file after playback starts
            tempFile.delete().catchError((e) => print('Error deleting temp file: $e'));
            return;
          }
        }
      } catch (e) {
        print('Error playing local file: $e');
      }
    }

    // Fall back to streaming if no local file exists or if there's an error
    try {
      final playlist = ConcatenatingAudioSource(children: [
        AudioSource.uri(
          Uri.parse(url),
          tag: currentSong ?? {'audio_url': url},
        ),
      ]);

      if (subsequentSongs != null) {
        for (var song in subsequentSongs) {
          if (song['audio_url'] != null) {
            playlist.add(AudioSource.uri(
              Uri.parse(song['audio_url']),
              tag: song,
            ));
          }
        }
      }

      await _audioPlayer.setAudioSource(playlist);
      _playlist = playlist;
      await _audioPlayer.play();
      _updateQueueStream();
    } catch (e) {
      print('Error streaming song: $e');
      throw Exception('Failed to play song: $e');
    }
  }

  Future<void> addTopHit(String songId, String artistId, int rank) async {
    try {
      await _supabase.from('top_hits').insert({
        'song_id': songId,
        'artist_id': artistId,
        'rank': rank,
        'play_count': 0,
      });
    } catch (e) {
      print('Error adding top hit: $e');
      throw Exception('Failed to add top hit: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getArtistTopHits(dynamic artistId) async {
    try {
      print('========= DEBUG LOGS =========');
      print('Artist ID received: $artistId');
      print('Artist ID type: ${artistId.runtimeType}');

      // Get the full artist data from recommended_artists
      final recommendedArtistData = await _supabase
          .from('recommended_artists')
          .select('*') // Select all columns to see what we have
          .eq('id', artistId)
          .maybeSingle();

      print('Full recommended artist data: $recommendedArtistData');

      // Safety check
      if (recommendedArtistData == null) {
        print('No artist data found');
        return [];
      }

      // Safely get the artist name
      final artistName = recommendedArtistData['artist'];
      print('Artist name extracted: $artistName');

      if (artistName == null) {
        print('Artist name is null');
        return [];
      }

      // Get songs
      final songResponse = await _supabase.from('songs').select('''
          id,
          title,
          artist,
          duration,
          audio_url,
          image_url
        ''').eq('artist', artistName).limit(10);

      print('Songs response: $songResponse');

      if (songResponse == null) {
        print('Song response is null');
        return [];
      }

      final transformedSongs =
          List<Map<String, dynamic>>.from(songResponse).map((song) {
        return {
          ...song,
          'rank': 0,
          'play_count': 0,
        };
      }).toList();

      print('Transformed songs count: ${transformedSongs.length}');
      print('========= END DEBUG LOGS =========');
      return transformedSongs;
    } catch (e) {
      print('Error in getArtistTopHits: $e');
      print('Error stack trace: ${StackTrace.current}');
      return []; // Return empty list instead of throwing
    }
  }

  Future<void> incrementTopHitPlayCount(String songId, String artistId) async {
    try {
      // First, find the top_hit record
      final response = await _supabase
          .from('top_hits')
          .select()
          .eq('song_id', songId)
          .eq('artist_id', artistId)
          .single();

      if (response != null) {
        // Update the play count
        await _supabase
            .from('top_hits')
            .update({'play_count': (response['play_count'] ?? 0) + 1})
            .eq('song_id', songId)
            .eq('artist_id', artistId);
      }
    } catch (e) {
      print('Error incrementing play count: $e');
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      final response =
          await _supabase.from('artists').select().eq('id', artistId).single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching artist details: $e');
      throw Exception('Failed to fetch artist details: $e');
    }
  }

  void _updateQueueStream() {
    try {
      final currentQueue = _playlist.sequence
          .map((source) => source.tag as Map<String, dynamic>)  // Changed: directly use the tag
          .toList();

      print('Debug - Queue length before removal: ${currentQueue.length}');  // Debug log
      
      // Skip the currently playing song
      if (currentQueue.isNotEmpty) {
        currentQueue.removeAt(0);
      }

      print('Debug - Queue length after removal: ${currentQueue.length}');  // Debug log
      print('Debug - Queue contents: $currentQueue');  // Debug log
      
      _queueController.add(currentQueue);
    } catch (e) {
      print('Error updating queue stream: $e');
      print('Error stack trace: ${StackTrace.current}');  // Added stack trace
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
    _currentSongController.close();
  }

  Future<List<Map<String, dynamic>>> searchSongs(String query,
      {String filter = 'all'}) async {
    try {
      var request = _supabase
          .from('songs')
          .select('id, title, image_url, artist, audio_url');

      switch (filter) {
        case 'songs':
          request = request.ilike('title', '%$query%');
          break;
        case 'artists':
          request = request.ilike('artist', '%$query%');
          break;
        default:
          request = request.or('title.ilike.%$query%,artist.ilike.%$query%');
      }

      final response = await request.limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search songs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAlbumSongs(String albumId) async {
    final cacheKey = 'album_songs_$albumId';
    
    try {
      // Try to fetch from network
      final response = await Supabase.instance.client
          .from('songs')
          .select()
          .eq('album_id', albumId)
          .order('track_number');

      final songs = List<Map<String, dynamic>>.from(response as List);
      
      // Cache the results
      await _localStorageService.saveData(cacheKey, songs);
      
      return songs;
    } catch (e) {
      print('Error fetching album songs from network: $e');
      
      // If network fetch fails, try to get from cache
      final cachedSongs = await _localStorageService.getData(cacheKey);
      if (cachedSongs != null) {
        return List<Map<String, dynamic>>.from(cachedSongs);
      }

      // If no cache and no network, check if any songs are downloaded
      final downloadedSongs = await getDownloadedSongsForAlbum(albumId);
      if (downloadedSongs.isNotEmpty) {
        return downloadedSongs;
      }
      
      // If nothing is available, rethrow the error
      rethrow;
    }
  }

  Future<void> playAllSongs(List<Map<String, dynamic>> songs) async {
    if (songs.isEmpty) return;

    try {
      // Play the first song
      final firstSong = songs[0];
      final audioUrl = firstSong['audio_url'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) {
        throw Exception('Song URL is missing');
      }
      await playSong(audioUrl);
    } catch (e) {
      throw Exception('Failed to play songs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('listening_history')
          .select('''
            *,
            songs:song_id (
              id,
              title,
              artist,
              image_url,
              audio_url
            )
          ''')
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching recently played: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPersonalizedPlaylists() async {
    try {
      final response = await Supabase.instance.client
          .from('playlists')
          .select()
          .eq('type', 'personalized')
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching personalized playlists: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopCharts() async {
    try {
      final response = await Supabase.instance.client
          .from('top_charts')
          .select('*, songs(*)')
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching top charts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getArtistSongs(String artistId) async {
    try {
      final response = await Supabase.instance.client
          .from('songs')
          .select()
          .eq('artist_id', artistId)
          .order('plays', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch artist songs: $e');
    }
  }

  Future<void> createPlaylist(String name, String description) async {
    await _supabase.from('playlists').insert({
      'name': name,
      'description': description,
      'user_id': _supabase.auth.currentUser?.id,
    });
  }

  Future<void> addToPlaylist(String playlistId, String songId) async {
    await _supabase.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id': songId,
    });
  }

  Future<void> addToQueue(Map<String, dynamic> song) async {
    try {
      await _playlist.add(
        AudioSource.uri(
          Uri.parse(song['audio_url']),
          tag: song,  // Pass the entire song object as the tag
        ),
      );
      _updateQueueStream();
    } catch (e) {
      print('Error adding to queue: $e');
      rethrow;
    }
  }

  Future<void> clearQueue() async {
    try {
      // Keep the current song
      if (_playlist.length > 1) {
        final currentSource = _playlist.sequence.first;
        await _playlist.clear();
        await _playlist.add(currentSource);
        _updateQueueStream();
      }
    } catch (e) {
      print('Error clearing queue: $e');
      rethrow;
    }
  }

  Future<void> playNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error playing next song: $e');
      rethrow;
    }
  }

  Future<void> playPrevious() async {
    await _audioPlayer.seekToPrevious();
  }

  Future<void> likeSong(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Check if song is already liked
      final existingLike = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', userId)
          .eq('song_id', songId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike the song
        await _supabase
            .from('liked_songs')
            .delete()
            .eq('user_id', userId)
            .eq('song_id', songId);
      } else {
        // Like the song
        await _supabase.from('liked_songs').insert({
          'user_id': userId,
          'song_id': songId,
          'liked_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error managing song like: $e');
      rethrow;
    }
  }

  Future<bool> isLiked(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('liked_songs')
          .select()
          .eq('user_id', userId)
          .eq('song_id', songId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking if song is liked: $e');
      return false;
    }
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await _audioPlayer.setShuffleModeEnabled(_shuffleEnabled);
  }

  Future<void> cycleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    await _audioPlayer.setLoopMode(_loopMode);
  }

  Future<void> followUser(String userId) async {
    await _supabase.from('follows').insert({
      'follower_id': _supabase.auth.currentUser?.id,
      'following_id': userId,
    });
  }

  Future<void> sharePlaylist(String playlistId, String userId) async {
    await _supabase.from('shared_playlists').insert({
      'playlist_id': playlistId,
      'shared_with': userId,
      'shared_by': _supabase.auth.currentUser?.id,
    });
  }

  Future<String?> _getAudioUrl(String songId) async {
    try {
      final songData = await _supabase
          .from('songs')
          .select('audio_url')
          .eq('id', songId)
          .single();

      print('Song data from DB: $songData');
      final audioUrl = songData['audio_url'];
      
      if (audioUrl != null && audioUrl.isNotEmpty) {
        print('Found audio_url in DB: $audioUrl');
        return audioUrl;
      }
      return null;
    } catch (e) {
      print('Error getting audio URL: $e');
      return null;
    }
  }

  Future<List<int>?> _downloadFromUrl(String url) async {
    try {
      print('Attempting to download from URL: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        print('Successfully downloaded ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('Download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading from URL: $e');
      return null;
    }
  }

  Future<void> downloadSong(Map<String, dynamic> song) async {
    final songId = song['id'];
    final albumId = song['album_id'];
    final originalImageUrl = song['image_url'];  // Store original image URL
    final albumImageUrl = song['album_image_url'];  // Store album image URL separately

    try {
      print('Starting download for song ID: $songId');
      
      if (await isSongDownloaded(songId)) {
        print('Song already downloaded: $songId');
        return;
      }

      final audioUrl = await _getAudioUrl(songId);
      if (audioUrl == null) {
        throw Exception('Could not find audio URL for song');
      }

      final bytes = await _downloadFromUrl(audioUrl);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to download audio file');
      }

      // Save audio file with a randomized name
      final secureFileName = '${DateTime.now().millisecondsSinceEpoch}_${Uri.encodeFull(songId)}.dat';
      final filePath = await _getSecureFilePath(secureFileName);
      
      // Basic XOR encryption
      final encryptedBytes = _xorEncrypt(bytes, songId);
      await File(filePath).writeAsBytes(encryptedBytes);

      // Create metadata preserving all original song data
      final metadata = {
        ...song,  // Keep all original song data
        'downloaded_at': DateTime.now().toIso8601String(),
        'secure_file': secureFileName,
        'original_image_url': originalImageUrl,  // Store original image URL
      };
      
      // Cache the song's image if available
      if (originalImageUrl != null && originalImageUrl.isNotEmpty) {
        final cachedImagePath = await _cacheImage(originalImageUrl, songId);
        metadata['cached_image_path'] = cachedImagePath;
      }

      await _localStorageService.saveData('metadata_$songId', metadata);

      // Handle album metadata separately
      if (albumId != null) {
        final albumMetadata = {
          'id': albumId,
          'title': song['album_title'],
          'artist': song['artist'],
          'image_url': albumImageUrl ?? song['image_url'],  // Use album image if available
          'original_image_url': albumImageUrl ?? song['image_url'],  // Store original album image
        };

        await _localStorageService.saveAlbumMetadata(albumId, albumMetadata);
        await _localStorageService.addDownloadedAlbumId(albumId);

        // Cache album image
        if (albumImageUrl != null) {
          final albumImagePath = await _cacheImage(albumImageUrl, 'album_$albumId');
          albumMetadata['cached_image_path'] = albumImagePath;
          await _localStorageService.saveAlbumMetadata(albumId, albumMetadata);
        }
      }

      await _updateDownloadedSongsList(metadata);
      print('Successfully downloaded song: $songId');
    } catch (e) {
      print('Error downloading song: $e');
      throw Exception('Failed to download song: $e');
    }
  }

  // Simple XOR encryption/decryption
  List<int> _xorEncrypt(List<int> data, String key) {
    final keyBytes = utf8.encode(key);
    final encrypted = List<int>.from(data);
    for (var i = 0; i < encrypted.length; i++) {
      encrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length];
    }
    return encrypted;
  }

  Future<bool> isSongDownloaded(String songId) async {
    try {
      // Check if metadata exists for this song
      final metadata = await _localStorageService.getData('metadata_$songId');
      if (metadata == null) return false;

      // Verify the secure file exists
      final secureFileName = metadata['secure_file'];
      if (secureFileName == null) return false;

      final filePath = await _getSecureFilePath(secureFileName);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('Error checking if song is downloaded: $e');
      return false;
    }
  }

  Future<List<int>?> _downloadFromStorage(String songId) async {
    try {
      print('Starting download process for song ID: $songId');
      
      // First verify the file exists
      final fileExists = await _supabase.storage
          .from('songs')
          .list(path: '')
          .then((files) => files.any((file) => file.name == '$songId.mp3'));

      if (!fileExists) {
        print('File $songId.mp3 not found in storage bucket');
        return null;
      }

      print('File found in storage, attempting download');
      
      // Try to download the file
      final bytes = await _supabase.storage
          .from('songs')
          .download('$songId.mp3');

      if (bytes.isEmpty) {
        print('Downloaded file is empty');
        return null;
      }

      print('Successfully downloaded ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      print('Storage download error:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      // Additional error info
      if (e is StorageException) {
        print('Storage error details: ${e.message}');
        print('Storage error status: ${e.statusCode}');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    try {
      final saved = await _localStorageService.getData('downloaded_songs');
      return List<Map<String, dynamic>>.from(saved ?? []);
    } catch (e) {
      print('Error getting downloaded songs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations() async {
    // Get user's listening history
    final history = await _supabase
        .from('listening_history')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('played_at', ascending: false)
        .limit(50);

    // Use this to get similar songs
    return await _supabase.rpc('get_recommendations', params: {
      'user_id': _supabase.auth.currentUser!.id,
      'history': history
    });
  }

  Future<List<int>> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download file');
  }

  Stream<List<Map<String, dynamic>>> get queueStream {
    // Emit current queue immediately when subscribed
    Future(() {
      if (_playlist.sequence.isNotEmpty) {
        _updateQueueStream();
      }
    });
    return _queueController.stream;
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      // Save current playback state and position
      final wasPlaying = _audioPlayer.playing;
      final position = await _audioPlayer.position;
      final currentIndex = _audioPlayer.currentIndex;

      // Adjust indices to account for the currently playing song
      oldIndex += 1; 
      newIndex += 1;

      final playlist = _playlist.sequence.toList();
      final item = playlist.removeAt(oldIndex);
      playlist.insert(newIndex, item);

      // Create new playlist without disrupting current playback
      final newPlaylist = ConcatenatingAudioSource(children: []);
      await newPlaylist.addAll(playlist.map((source) => 
        AudioSource.uri(
          Uri.parse(source.tag['audio_url']),
          tag: source.tag,
        )).toList()
      );

      // Update playlist while preserving current playback
      _playlist = newPlaylist;
      await _audioPlayer.setAudioSource(
        _playlist,
        initialIndex: currentIndex,
        initialPosition: position,
      );

      // Restore playback state
      if (wasPlaying) {
        await _audioPlayer.play();
      }

      _updateQueueStream();
    } catch (e) {
      print('Error reordering queue: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> get currentSongStream =>
      _currentSongController.stream;

  Future<void> _recordPlayHistory(Map<String, dynamic> song) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // First check if this song exists in listening_history
      final existingRecord = await _supabase
          .from('listening_history')
          .select()
          .eq('user_id', userId)
          .eq('song_id', song['id'])
          .single();

      if (existingRecord != null) {
        // Update existing record with new timestamp
        await _supabase
            .from('listening_history')
            .update({
              'played_at': DateTime.now().toIso8601String(),
              'play_count': (existingRecord['play_count'] ?? 0) + 1,
            })
            .eq('id', existingRecord['id']);
      } else {
        // Create new record
        await _supabase.from('listening_history').insert({
          'user_id': userId,
          'song_id': song['id'],
          'played_at': DateTime.now().toIso8601String(),
          'play_count': 1,
        });
      }
    } catch (e) {
      print('Error recording play history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongsForAlbum(String albumId) async {
    try {
      final allDownloaded = await getDownloadedSongs();
      return allDownloaded.where((song) => song['album_id'] == albumId).toList();
    } catch (e) {
      print('Error getting downloaded songs for album: $e');
      return [];
    }
  }

  Future<void> _updateDownloadedSongsList(Map<String, dynamic> songMetadata) async {
    try {
      final downloadedSongs = await getDownloadedSongs();
      downloadedSongs.add(songMetadata);
      await _localStorageService.saveData('downloaded_songs', downloadedSongs);
    } catch (e) {
      print('Error updating downloaded songs list: $e');
    }
  }

  Future<Map<String, dynamic>?> getAlbumOffline(String albumId) async {
    try {
      return await _localStorageService.getAlbumMetadata(albumId);
    } catch (e) {
      print('Error getting offline album: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedAlbums() async {
    try {
      final albumIds = await _localStorageService.getDownloadedAlbumIds();
      final albums = <Map<String, dynamic>>[];
      
      for (final id in albumIds) {
        final albumData = await _localStorageService.getAlbumMetadata(id);
        if (albumData != null) {
          albums.add(albumData);
        }
      }
      
      return albums;
    } catch (e) {
      print('Error getting downloaded albums: $e');
      return [];
    }
  }

  // Add this helper method
  Future<String> _getSecureFilePath(String fileName) async {
    final directory = await getApplicationSupportDirectory(); // More secure than getApplicationDocumentsDirectory
    return '${directory.path}/$fileName';
  }

  Future<String> _cacheImage(String imageUrl, String id) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationSupportDirectory();
        final imagePath = '${directory.path}/images/${id}_image.jpg';
        
        // Create images directory if it doesn't exist
        final imageDir = Directory('${directory.path}/images');
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        
        // Save the image
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(response.bodyBytes);
        
        return imagePath;
      }
      throw Exception('Failed to download image');
    } catch (e) {
      print('Error caching image: $e');
      rethrow;
    }
  }

  Future<String?> getCachedImagePath(String id) async {
    try {
      // First check for cached image
      final directory = await getApplicationSupportDirectory();
      final imagePath = '${directory.path}/images/${id}_image.jpg';
      final imageFile = File(imagePath);
      
      if (await imageFile.exists()) {
        return imagePath;
      }

      // If no cached image, check metadata for original image URL
      final metadata = await _localStorageService.getData('metadata_$id');
      if (metadata != null && metadata['original_image_url'] != null) {
        // Try to cache the original image
        final cachedPath = await _cacheImage(metadata['original_image_url'], id);
        return cachedPath;
      }
      
      return null;
    } catch (e) {
      print('Error getting cached image path: $e');
      return null;
    }
  }
}
