import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'encrypted_storage_service.dart';

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
      final response = await _supabase
          .from('albums')
          .select()
          .eq('category', 'hits') // Filter for "hits" category
          .order('created_at');

      if (response == null) {
        throw Exception('No data received from Supabase');
      }

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching albums: $e');
      rethrow;
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
      Map<String, dynamic>? nextSong}) async {
    try {
      // Create playlist with current song
      final playlist = ConcatenatingAudioSource(children: [
        AudioSource.uri(
          Uri.parse(
              currentSong?['audio_url'] ?? currentSong?['audio_url'] ?? url),
          tag: currentSong ?? {'url': url},
        ),
      ]);

      // If nextSong is provided, add it to playlist
      if (nextSong != null && nextSong['audio_url'] != null) {
        playlist.add(
          AudioSource.uri(
            Uri.parse(nextSong['audio_url']),
            tag: nextSong,
          ),
        );
      }

      await _audioPlayer.setAudioSource(
        playlist,
        preload: true,
        initialPosition: Duration.zero,
        initialIndex: 0,
      );

      _playlist = playlist;
      await _audioPlayer.play();
      _updateQueueStream();

      // Record play history immediately after starting playback
      if (currentSong != null) {
        await _recordPlayHistory(currentSong);
      }
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

  //
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

// Add this method for incrementing play count
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

  // Method to increment play count for a top hit
  // Future<void> incrementTopHitPlayCount(String songId, String artistId) async {
  //   try {
  //     await _supabase.rpc('increment_top_hit_play_count', params: {
  //       'song_id': songId,
  //       'artist_id': artistId,
  //     });
  //   } catch (e) {
  //     print('Error incrementing play count: $e');
  //   }
  // }

  void _updateQueueStream() {
    try {
      final currentQueue = _playlist.sequence
          .map((source) => {
                'id': source.tag['url'] ?? '',
                'title': source.tag['title'] ?? 'Unknown Title',
                'artist': source.tag['artist'] ?? 'Unknown Artist',
                'image_url': source.tag['image_url'] ?? '',
                'audio_url': source.tag['url'] ?? '',
              })
          .toList();

      // Skip the currently playing song
      if (currentQueue.isNotEmpty) {
        currentQueue.removeAt(0);
      }

      _queueController.add(currentQueue);
    } catch (e) {
      print('Error updating queue stream: $e');
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
    try {
      final response = await Supabase.instance.client
          .from('songs')
          .select()
          .eq('album_id', albumId)
          .order('track_number');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch album songs: $e');
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
          tag: {
            'url': song['audio_url'],
            'title': song['title'],
            'artist': song['artist'],
            'image_url': song['image_url'],
          },
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

  Future<void> downloadSong(Map<String, dynamic> song) async {
    try {
      // Validate required fields
      if (song['id'] == null || song['audio_url'] == null) {
        throw Exception('Invalid song data: missing id or audio_url');
      }

      // Check if already downloaded
      final isDownloaded = await isSongDownloaded(song['id']);
      if (isDownloaded) {
        throw Exception('Song already downloaded');
      }

      // Download audio file
      final response = await http.get(Uri.parse(song['audio_url']));
      if (response.statusCode != 200) {
        throw Exception('Failed to download song: HTTP ${response.statusCode}');
      }

      // Encrypt and save
      final fileName = 'song_${song['id']}';
      final filePath = await _encryptedStorage.encryptAndSave(
        response.bodyBytes,
        fileName,
      );

      // Prepare metadata
      final metadata = {
        'user_id': _supabase.auth.currentUser?.id,
        'song_id': song['id'],
        'file_path': filePath,
        'title': song['title'] ?? 'Unknown Title',
        'artist': song['artist'] ?? 'Unknown Artist',
        'image_url': song['image_url'],
        'downloaded_at': DateTime.now().toIso8601String(),
      };

      // Save metadata to Supabase
      final result = await _supabase.from('downloaded_songs').upsert(metadata);
      
      if (result == null) {
        throw Exception('Failed to save download metadata');
      }

    } catch (e) {
      print('Error downloading song: $e');
      // Clean up downloaded file if metadata save fails
      // You might want to add cleanup code here
      rethrow;
    }
  }

  Future<bool> isSongDownloaded(String songId) async {
    return await _encryptedStorage.isDownloaded('song_$songId');
  }

  Future<List<Map<String, dynamic>>> getDownloadedSongs() async {
    return await _localStorageService.getDownloadedSongs();
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

  Stream<List<Map<String, dynamic>>> get queueStream => _queueController.stream;

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      // Adjust indices to account for the currently playing song
      oldIndex += 1;
      newIndex += 1;

      final playlist = _playlist.sequence.toList();
      final item = playlist.removeAt(oldIndex);
      playlist.insert(newIndex, item);

      await _playlist.clear();
      await _playlist.addAll(playlist);
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
}
