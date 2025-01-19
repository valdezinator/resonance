import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import '../providers/music_providers.dart';

mixin FloatingPlayerMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  Widget buildFloatingBottomPlayer({
    Map<String, dynamic>? currentSong,
    required MusicService musicService,
    required Function(Map<String, dynamic>?) onSongPlay,
  }) {
    if (currentSong == null) return const SizedBox.shrink();

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
            key: ValueKey(currentSong['id']),
            currentSong: currentSong,
            onClose: () => onSongPlay(null),
          ),
        ),
      ),
    );
  }
}
