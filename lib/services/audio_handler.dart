import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyBackgroundTask extends BackgroundAudioTask {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    // Check if the URL is provided in params
    if (params != null && params['url'] != null) {
      await _player.setUrl(params['url']);
      _player.play();
    }

    // Listen to player state changes and update clients
    _player.playerStateStream.listen((state) {
      AudioServiceBackground.setState(
        playing: state.playing,
        processingState: _mapProcessingState(state.processingState),
      );
    });
  }

  @override
  Future<void> onStop() async {
    await _player.stop();
    await super.onStop();
  }

  @override
  Future<void> onPlay() async {
    await _player.play();
  }

  @override
  Future<void> onPause() async {
    await _player.pause();
  }

  // Map Just Audio processing state to Audio Service processing state
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      default:
        return AudioProcessingState.idle;
    }
  }
}
