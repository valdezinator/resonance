import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/music_service.dart';

class FullScreenPlayer extends StatefulWidget {
  final MusicService musicService;
  final Map<String, dynamic> currentSong;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSongChange;

  const FullScreenPlayer({
    Key? key,
    required this.musicService,
    required this.currentSong,
    required this.onClose,
    required this.onSongChange,
  }) : super(key: key);

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  PaletteGenerator? _palette;
  bool _isSeeking = false;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  @override
  void initState() {
    super.initState();
    _loadImagePalette();

    // Listen for song changes
    widget.musicService.currentSongStream.listen((newSong) {
      if (mounted && newSong != null && newSong != widget.currentSong) {
        widget.onSongChange(newSong);
        _loadImagePalette();
      }
    });
  }

  Future<void> _loadImagePalette() async {
    try {
      final imageProvider = NetworkImage(widget.currentSong['image_url']);
      final palette = await PaletteGenerator.fromImageProvider(imageProvider);
      if (mounted) {
        setState(() {
          _palette = palette;
        });
      }
    } catch (e) {
      print('Error loading palette: $e');
    }
  }

  IconData _getRepeatIcon() {
    switch (_loopMode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.all:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      default:
        return Icons.repeat;
    }
  }

  Color _getActiveColor(bool isActive, Color defaultColor) {
    return isActive ? Colors.green : defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final dominantColor = _palette?.dominantColor?.color ?? Colors.purple;
    final textColor = _palette?.dominantColor?.bodyTextColor ?? Colors.white;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dominantColor,
              dominantColor.withOpacity(0.5),
              Colors.black,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                      onPressed: widget.onClose,
                    ),
                    Text(
                      'Now Playing',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.queue_music, color: textColor),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.4,
                                maxChildSize: 0.8,
                                builder: (context, scrollController) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A202B),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Handle bar
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[600],
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Queue',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.clear_all,
                                                  color: textColor),
                                              onPressed: widget
                                                  .musicService.clearQueue,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Queue list would go here
                                      Expanded(
                                        child: StreamBuilder<
                                            List<Map<String, dynamic>>>(
                                          stream:
                                              widget.musicService.queueStream,
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }

                                            final queue = snapshot.data!;
                                            return ReorderableListView.builder(
                                              itemCount: queue.length,
                                              onReorder: (oldIndex, newIndex) {
                                                widget.musicService
                                                    .reorderQueue(
                                                  oldIndex,
                                                  newIndex > oldIndex
                                                      ? newIndex - 1
                                                      : newIndex,
                                                );
                                              },
                                              itemBuilder: (context, index) {
                                                final song = queue[index];
                                                return ListTile(
                                                  key: ValueKey(song['id']),
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    child: Image.network(
                                                      song['image_url'],
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    song['title'],
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  subtitle: Text(
                                                    song['artist'],
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[400]),
                                                  ),
                                                  trailing:
                                                      ReorderableDragStartListener(
                                                    index: index,
                                                    child: const Icon(
                                                      Icons.drag_handle,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: textColor),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Hero(
                    tag: 'album_art_${widget.currentSong['id']}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.currentSong['image_url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentSong['title'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.currentSong['artist'],
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: StreamBuilder<Duration>(
                  stream: widget.musicService.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: widget.musicService.durationStream,
                      builder: (context, snapshot) {
                        final duration = snapshot.data ?? Duration.zero;
                        return ProgressBar(
                          progress: position,
                          total: duration,
                          buffered: duration,
                          onSeek: (duration) {
                            widget.musicService.seek(duration);
                          },
                          baseBarColor: const Color.fromARGB(255, 23, 80, 42)
                              .withOpacity(0.2),
                          progressBarColor:
                              const Color.fromARGB(255, 21, 112, 44),
                          bufferedBarColor:
                              const Color.fromARGB(255, 107, 119, 139)
                                  .withOpacity(0.3),
                          thumbColor: textColor,
                          timeLabelTextStyle: TextStyle(color: textColor),
                        );
                      },
                    );
                  },
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.only(
                    left: 32.0, right: 32.0, bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: _getActiveColor(_isShuffleEnabled, textColor),
                      ),
                      onPressed: () {
                        setState(() {
                          _isShuffleEnabled = !_isShuffleEnabled;
                        });
                        widget.musicService.toggleShuffle();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: textColor),
                      iconSize: 40,
                      onPressed: widget.musicService.playPrevious,
                    ),
                    StreamBuilder<PlayerState>(
                      stream: widget.musicService.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            width: 72.0,
                            height: 72.0,
                            child: const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        }

                        return IconButton(
                          icon: Icon(
                            playing == true
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: Colors.white,
                          ),
                          iconSize: 72,
                          onPressed: playing == true
                              ? widget.musicService.pause
                              : widget.musicService.resume,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: textColor),
                      iconSize: 40,
                      onPressed: widget.musicService.playNext,
                    ),
                    IconButton(
                      icon: Icon(
                        _getRepeatIcon(),
                        color: _getActiveColor(
                            _loopMode != LoopMode.off, textColor),
                      ),
                      onPressed: () {
                        widget.musicService.cycleLoopMode().then((_) {
                          setState(() {
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
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
