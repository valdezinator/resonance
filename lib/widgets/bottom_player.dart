import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import '../services/music_service.dart';
import 'dart:ui';
import 'full_screen_player.dart';
import 'dart:io';

class BottomPlayer extends StatefulWidget {
  final MusicService musicService;
  final Map<String, dynamic>? currentSong;
  final VoidCallback? onClose;

  const BottomPlayer({
    Key? key,
    required this.musicService,
    this.currentSong,
    this.onClose,
  }) : super(key: key);

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer> {
  bool isPlaying = false;
  bool isLiked = false;

  @override
  void didUpdateWidget(BottomPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the current song has changed
    if (widget.currentSong?['id'] != oldWidget.currentSong?['id']) {
      setState(() {});
      _checkLikeStatus();
    }
  }

  void _showFullScreenPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenPlayer(
            musicService: widget.musicService,
            currentSong: widget.currentSong!,
            onClose: () => Navigator.pop(context),
            onSongChange: (song) {
              setState(() {});  // Refresh UI when song changes
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
    // Initialize player state based on musicService
    widget.musicService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });
      }
    });
  }

  Future<void> _checkLikeStatus() async {
    if (widget.currentSong != null) {
      final liked = await widget.musicService.isLiked(widget.currentSong!['id']);
      if (mounted) {
        setState(() {
          isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    try {
      if (widget.currentSong == null) return;
      
      await widget.musicService.likeSong(widget.currentSong!['id']);
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
    if (widget.currentSong == null) return const SizedBox();

    return FutureBuilder<String?>(
      future: widget.musicService.getCachedImagePath(widget.currentSong!['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Use cached image
          return Hero(
            tag: 'album_art_${widget.currentSong!['id']}',
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
          tag: 'album_art_${widget.currentSong!['id']}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.currentSong!['image_url'] as String,
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
    if (widget.currentSong == null || widget.currentSong!['title'] == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showFullScreenPlayer,
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
                                    widget.currentSong!['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    widget.currentSong!['artist'] as String,
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
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.green : Colors.white,  // Changed from red to green
                                  ),
                                  iconSize: 24,
                                  onPressed: _toggleLike,
                                ),
                                StreamBuilder<PlayerState>(
                                  stream: widget.musicService.playerStateStream,
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
                                        onPressed: widget.musicService.resume,
                                      );
                                    } else {
                                      return IconButton(
                                        icon: const Icon(Icons.pause),
                                        iconSize: 24,
                                        color: Colors.white,
                                        onPressed: widget.musicService.pause,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  iconSize: 24,
                                  color: Colors.white,
                                  onPressed: widget.musicService.playNext,
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
