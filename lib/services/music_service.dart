import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';
import 'package:http/http.dart' as http;

class MusicService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _supabase = Supabase.instance.client;
  late ConcatenatingAudioSource _playlist;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleEnabled = false;
  final _localStorageService = LocalStorageService();

  MusicService() {
    _playlist = ConcatenatingAudioSource(children: []);
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    // Configure for gapless playback
    await _audioPlayer.setAudioSource(
      _playlist,
      preload: true,
      initialPosition: Duration.zero,
      initialIndex: 0,
    );

    // Enable gapless playback
    await _audioPlayer.setLoopMode(LoopMode.off);
    await _audioPlayer.setShuffleModeEnabled(false);
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

  Future<void> playSong(String url, {String? nextSongUrl}) async {
    try {
      await _playlist.clear();

      final sources = [
        AudioSource.uri(Uri.parse(url), tag: {'url': url}),
      ];

      if (nextSongUrl != null) {
        sources.add(
            AudioSource.uri(Uri.parse(nextSongUrl), tag: {'url': nextSongUrl}));
      }

      await _playlist.addAll(sources);
      await _audioPlayer.seek(Duration.zero, index: 0);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
      rethrow;
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
  }

  Future<List<Map<String, dynamic>>> searchSongs(String query,
      {String filter = 'all'}) async {
    try {
      var request = _supabase.from('songs').select();

      switch (filter) {
        case 'songs':
          request = request.or('title.ilike.%$query%');
          break;
        case 'artists':
          request = request.or('artist.ilike.%$query%');
          break;
        case 'albums':
          request = request.or('album.ilike.%$query%');
          break;
        default:
          request = request.or(
              'title.ilike.%$query%,artist.ilike.%$query%,album.ilike.%$query%');
      }

      final response = await request;
      return List<Map<String, dynamic>>.from(response as List);
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

  final List<Map<String, dynamic>> _queue = [];

  void addToQueue(Map<String, dynamic> song) {
    _queue.add(song);
  }

  Future<void> playNext() async {
    if (_queue.isNotEmpty) {
      final nextSong = _queue.removeAt(0);
      await playSong(nextSong['mp3_url']);
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
    final bytes = await _downloadFile(song['mp3_url']);
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
}
