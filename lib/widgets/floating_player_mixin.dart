import 'package:flutter/material.dart';
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';

mixin FloatingPlayerMixin {
  Widget buildFloatingBottomPlayer({
    required Map<String, dynamic>? currentSong,
    required MusicService musicService,
    required Function(Map<String, dynamic>) onSongPlay,
  }) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: musicService.currentSongStream,
      initialData: currentSong,
      builder: (context, snapshot) {
        final song = snapshot.data;
        if (song == null) return const SizedBox.shrink();

        return Positioned(
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
                key: ValueKey(song['id']),
                musicService: musicService,
                currentSong: song,
                onClose: () => onSongPlay({}),
              ),
            ),
          ),
        );
      },
    );
  }
}
