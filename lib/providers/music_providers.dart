import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_service.dart';

// Core providers
final musicServiceProvider = Provider<MusicService>((ref) {
  final service = MusicService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Player state providers
final currentSongProvider =
    StateNotifierProvider<CurrentSongNotifier, Map<String, dynamic>?>(
  (ref) => CurrentSongNotifier(),
);

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(musicServiceProvider).playerStateStream;
});

final positionStreamProvider = StreamProvider<Duration>((ref) {
  return ref.watch(musicServiceProvider).positionStream;
});

final durationStreamProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(musicServiceProvider).durationStream;
});

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playerStateProvider).maybeWhen(
        data: (state) => state.playing,
        orElse: () => false,
      );
});

// Queue management
final queueProvider =
    StateNotifierProvider<QueueNotifier, List<Map<String, dynamic>>>((ref) {
  return QueueNotifier(ref.watch(musicServiceProvider));
});

// Download state providers
final downloadProgressProvider =
    StreamProvider.family<double, String>((ref, songId) {
  return ref.watch(musicServiceProvider).downloadProgressStream.map((progress) {
    return progress[songId] ?? 0.0;
  });
});

final isDownloadingProvider = StateProvider.family<bool, String>((ref, songId) {
  return false;
});

// Player controls provider
final playerControlsProvider = Provider((ref) => PlayerControls(ref));

// Notifiers
class CurrentSongNotifier extends StateNotifier<Map<String, dynamic>?> {
  CurrentSongNotifier() : super(null);

  void updateCurrentSong(Map<String, dynamic>? song) {
    state = song;
  }
}

class QueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final MusicService _musicService;

  QueueNotifier(this._musicService) : super([]) {
    _musicService.queueStream.listen((queue) {
      state = queue;
    });
  }

  void updateQueue(List<Map<String, dynamic>> queue) {
    state = queue;
  }
}

// Controls class
class PlayerControls {
  final Ref _ref;

  PlayerControls(this._ref);

  Future<void> playSong(Map<String, dynamic> song) async {
    final musicService = _ref.read(musicServiceProvider);
    await musicService.playSong(
      song['audio_url'],
      currentSong: song,
    );
    _ref.read(currentSongProvider.notifier).updateCurrentSong(song);
  }

  Future<void> play() async {
    await _ref.read(musicServiceProvider).resume();
  }

  Future<void> pause() async {
    await _ref.read(musicServiceProvider).pause();
  }

  Future<void> seek(Duration position) async {
    await _ref.read(musicServiceProvider).seek(position);
  }

  Future<void> next() async {
    await _ref.read(musicServiceProvider).playNext();
  }

  Future<void> previous() async {
    await _ref.read(musicServiceProvider).playPrevious();
  }

  Future<void> toggleShuffle() async {
    await _ref.read(musicServiceProvider).toggleShuffle();
  }

  Future<void> cycleLoopMode() async {
    await _ref.read(musicServiceProvider).cycleLoopMode();
  }
}
