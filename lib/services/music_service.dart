import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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

  MusicService() {
    _playlist = ConcatenatingAudioSource(children: []);
    _initAudioPlayer();
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

      // If no next song provided, fetch the next song from database
      if (nextSong == null && currentSong != null) {
        final response = await _supabase
            .from('songs')
            .select()
            .gt('id',
                currentSong['id']) // Get songs with ID greater than current
            .order('id') // Order by ID
            .limit(1) // Get just the next song
            .single(); // Get as single record

        if (response != null) {
          nextSong = response;
        }
      }

      // Add next song if available
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
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
    }
  }

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
      final response = await Supabase.instance.client
          .from('recently_played')
          .select('*, songs(*)')
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
    await _supabase.from('liked_songs').insert({
      'user_id': _supabase.auth.currentUser?.id,
      'song_id': songId,
      'liked_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isLiked(String songId) async {
    final response = await _supabase
        .from('liked_songs')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id)
        .eq('song_id', songId)
        .single();
    return response != null;
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
    // Download song file
    final bytes = await _downloadFile(song['audio_url']);
    // Save to local storage
    await _localStorageService.saveSong(song['id'], bytes);
    // Update downloaded songs list
    await _localStorageService.addToDownloadedSongs(song);
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
}
