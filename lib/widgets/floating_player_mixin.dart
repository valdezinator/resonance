import 'package:flutter/material.dart';
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';

mixin FloatingPlayerMixin {
  Widget buildFloatingBottomPlayer({
    Map<String, dynamic>? currentSong,
    required MusicService musicService,
    required Function(Map<String, dynamic>?) onSongPlay,
  }) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: musicService.currentSongStream,
      builder: (context, snapshot) {
        final song = snapshot.data ?? currentSong;
        if (song == null) return const SizedBox.shrink();

        if (snapshot.hasData && snapshot.data?['id'] != currentSong?['id']) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onSongPlay(snapshot.data);
          });
        }

        return AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 2,
          right: 2,
          bottom: 5,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BottomPlayer(
                key: ValueKey('player_${song['id']}'),
                musicService: musicService,
                currentSong: song,
                onClose: () => onSongPlay(null),
              ),
            ),
          ),
        );
      },
    );
  }
}
