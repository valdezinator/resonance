import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/music_service.dart';

class FullScreenPlayer extends StatefulWidget {
  final MusicService musicService;
  final Map<String, dynamic> currentSong;
  final VoidCallback onClose;

  const FullScreenPlayer({
    Key? key,
    required this.musicService,
    required this.currentSong,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  PaletteGenerator? _palette;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _loadImagePalette();
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
                    IconButton(
                      icon: Icon(Icons.more_vert, color: textColor),
                      onPressed: () {},
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
                          baseBarColor:
                              const Color(0xFF0C0F14).withOpacity(0.2),
                          progressBarColor: const Color(0xFF0C0F14),
                          bufferedBarColor:
                              const Color(0xFF0C0F14).withOpacity(0.3),
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
                      icon: Icon(Icons.shuffle, color: textColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: textColor),
                      iconSize: 40,
                      onPressed: () {},
                    ),
                    StreamBuilder<PlayerState>(
                      stream: widget.musicService.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;

                        return IconButton(
                          icon: Icon(
                            playing == true
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: textColor,
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
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.repeat, color: textColor),
                      onPressed: () {},
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
