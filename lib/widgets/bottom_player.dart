import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_service.dart';
import 'dart:ui';
import 'full_screen_player.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';

class BottomPlayer extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentSong;
  final VoidCallback onClose;

  const BottomPlayer({
    Key? key,
    required this.currentSong,
    required this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends ConsumerState<BottomPlayer> {
  bool isPlaying = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
    // Initialize player state based on musicService
    ref.read(musicServiceProvider).playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });

    // Listen to song changes
    ref.read(musicServiceProvider).currentSongStream.listen((song) {
      if (mounted && song != null) {
        ref.read(currentSongProvider.notifier).updateCurrentSong(song);
        _checkLikeStatus();
      }
    });
  }

  @override
  void didUpdateWidget(BottomPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the current song has changed
    final currentSong = ref.read(currentSongProvider);
    if (currentSong != null && currentSong != widget.currentSong) {
      _checkLikeStatus();
      setState(() {});
    }
  }

  Future<void> _checkLikeStatus() async {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong != null) {
      final liked =
          await ref.read(musicServiceProvider).isLiked(currentSong['id']);
      if (mounted) {
        setState(() {
          isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      final currentSong = ref.read(currentSongProvider);
      if (currentSong == null) return;

      await ref.read(musicServiceProvider).likeSong(currentSong['id']);
      await _checkLikeStatus(); // Refresh like status after toggle
    } catch (e) {
      print('Error toggling like: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSongImage() {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong == null) return const SizedBox();

    return FutureBuilder<String?>(
      future:
          ref.read(musicServiceProvider).getCachedImagePath(currentSong['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Use cached image
          return Hero(
            tag: 'album_art_${currentSong['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(snapshot.data!),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        // Fallback to network image
        return Hero(
          tag: 'album_art_${currentSong['id']}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              currentSong['image_url'] as String,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[800],
                  child: Icon(Icons.music_note, color: Colors.white),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[800],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current song to update UI when it changes
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider);
    final controls = ref.watch(playerControlsProvider);
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return FullScreenPlayer(
                onClose: () => Navigator.pop(context),
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOut)),
                ),
                child: child,
              );
            },
          ),
        );
      },
      child: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: Offset(0, 0),
        child: Container(
          // color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              // Blur portion of the bottom player
              filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Song image with Hero widget
                            _buildSongImage(),
                            const SizedBox(width: 12),
                            // Song info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    currentSong['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    currentSong['artist'] as String,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked
                                        ? Colors.green
                                        : Colors
                                            .white, // Changed from red to green
                                  ),
                                  iconSize: 24,
                                  onPressed: _toggleLike,
                                ),
                                StreamBuilder<PlayerState>(
                                  stream: ref
                                      .read(musicServiceProvider)
                                      .playerStateStream,
                                  builder: (context, snapshot) {
                                    final playerState = snapshot.data;
                                    final processingState =
                                        playerState?.processingState;
                                    final playing = playerState?.playing;

                                    if (processingState ==
                                            ProcessingState.loading ||
                                        processingState ==
                                            ProcessingState.buffering) {
                                      return Container(
                                        margin: const EdgeInsets.all(8.0),
                                        width: 24.0,
                                        height: 24.0,
                                        child: const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      );
                                    } else if (playing != true) {
                                      return IconButton(
                                        icon: const Icon(Icons.play_arrow),
                                        iconSize: 24,
                                        color: Colors.white,
                                        onPressed: ref
                                            .read(musicServiceProvider)
                                            .resume,
                                      );
                                    } else {
                                      return IconButton(
                                        icon: const Icon(Icons.pause),
                                        iconSize: 24,
                                        color: Colors.white,
                                        onPressed: ref
                                            .read(musicServiceProvider)
                                            .pause,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 24,
                                  color: Colors.white,
                                  onPressed:
                                      ref.read(musicServiceProvider).playNext,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
