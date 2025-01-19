import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/music_service.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import '../screens/album_details_page.dart';
import '../screens/library_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LyricLine {
  final Duration timestamp;
  final String text;
  final List<LyricWord> words;

  LyricLine({
    required this.timestamp,
    required this.text,
    required this.words,
  });
}

class LyricWord {
  final Duration timestamp;
  final String text;
  final int index;

  LyricWord({
    required this.timestamp,
    required this.text,
    required this.index,
  });
}

class FullScreenPlayer extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const FullScreenPlayer({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends ConsumerState<FullScreenPlayer> {
  PaletteGenerator? _palette;
  bool _isSeeking = false;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  List<LyricLine> _parsedLyrics = [];
  String? _currentWord;
  int _currentLineIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadImagePalette();
    _initializePlayerState();
    _loadLyrics();

    // Listen to song changes
    ref.read(musicServiceProvider).currentSongStream.listen((song) {
      if (mounted && song != null) {
        ref.read(currentSongProvider.notifier).updateCurrentSong(song);
        _loadImagePalette();
        _loadLyrics();
      }
    });
  }

  @override
  void didUpdateWidget(FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadImagePalette();
  }

  Future<void> _initializePlayerState() async {
    // Get initial shuffle state from music service
    final shuffleMode = await ref.read(musicServiceProvider).getShuffleMode();
    setState(() {
      _isShuffleEnabled = shuffleMode;
    });
  }

  Future<void> _loadImagePalette() async {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong == null || currentSong['image_url'] == null) return;

    try {
      final imageProvider = NetworkImage(currentSong['image_url']);
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

  Future<void> _loadPaletteFromProvider(ImageProvider imageProvider) async {
    try {
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

  Future<void> _loadLyrics() async {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong == null) return;

    try {
      final response = await Supabase.instance.client
          .from('songs')
          .select('song_lyrics')
          .eq('id', currentSong['id'])
          .single();

      if (response == null || response['song_lyrics'] == null) {
        setState(() {
          _parsedLyrics = [];
        });
        return;
      }

      final lyrics = response['song_lyrics'] as String;
      final List<LyricLine> parsedLines = [];

      for (String line in lyrics.split('\n')) {
        if (line.trim().isEmpty) continue;

        // Parse timestamp and text
        final match =
            RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)').firstMatch(line);
        if (match != null) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final milliseconds = int.parse(match.group(3)!) * 10;
          final text = match.group(4)!.trim();

          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );

          // Parse word timestamps if they exist
          List<LyricWord> words = [];
          int wordIndex = 0;

          // Split text into words and create word objects
          for (String word in text.split(' ')) {
            final wordMatch =
                RegExp(r'\{(\d{2}):(\d{2})\.(\d{2})\}(.*)').firstMatch(word);
            if (wordMatch != null) {
              final wordMinutes = int.parse(wordMatch.group(1)!);
              final wordSeconds = int.parse(wordMatch.group(2)!);
              final wordMilliseconds = int.parse(wordMatch.group(3)!) * 10;
              final wordText = wordMatch.group(4)!;

              words.add(LyricWord(
                timestamp: Duration(
                  minutes: wordMinutes,
                  seconds: wordSeconds,
                  milliseconds: wordMilliseconds,
                ),
                text: wordText,
                index: wordIndex++,
              ));
            } else {
              words.add(LyricWord(
                timestamp: timestamp,
                text: word,
                index: wordIndex++,
              ));
            }
          }

          parsedLines.add(LyricLine(
            timestamp: timestamp,
            text: text,
            words: words,
          ));
        }
      }

      setState(() {
        _parsedLyrics = parsedLines;
      });
    } catch (e) {
      print('Error loading lyrics: $e');
      setState(() {
        _parsedLyrics = [];
      });
    }
  }

  Widget _buildAlbumArt() {
    final currentSong = ref.watch(currentSongProvider);
    if (currentSong == null) return const SizedBox.shrink();

    return FutureBuilder<String?>(
      future:
          ref.read(musicServiceProvider).getCachedImagePath(currentSong['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final imageProvider = FileImage(File(snapshot.data!));
          _loadPaletteFromProvider(imageProvider);

          return Hero(
            tag: 'album_art_${currentSong['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: imageProvider,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        if (currentSong['image_url'] != null) {
          final networkImageProvider = NetworkImage(currentSong['image_url']);
          _loadPaletteFromProvider(networkImageProvider);

          return Hero(
            tag: 'album_art_${currentSong['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: networkImageProvider,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    color: Colors.grey[800],
                    child:
                        Icon(Icons.music_note, color: Colors.white, size: 64),
                  );
                },
              ),
            ),
          );
        }

        return Container(
          color: Colors.grey[800],
          child: Icon(Icons.music_note, color: Colors.white, size: 64),
        );
      },
    );
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

  Widget _buildProgressBar(
      Duration position, Duration duration, Color textColor) {
    return Column(
      children: [
        ProgressBar(
          progress: position,
          total: duration,
          buffered: duration,
          onSeek: (duration) {
            ref.read(musicServiceProvider).seek(duration);
          },
          baseBarColor: const Color.fromARGB(255, 23, 80, 42).withOpacity(0.2),
          progressBarColor: const Color.fromARGB(255, 21, 112, 44),
          bufferedBarColor:
              const Color.fromARGB(255, 107, 119, 139).withOpacity(0.3),
          thumbRadius: 0,
          barHeight: 6, // Increased thickness
          timeLabelTextStyle: TextStyle(color: textColor),
          timeLabelPadding: 10, // Add padding between bar and labels
        ),
        const SizedBox(height: 16), // Add space after progress bar
      ],
    );
  }

  Widget _buildControlButton(
      String assetPath, bool isActive, VoidCallback onPressed) {
    return IconButton(
      icon: SvgPicture.asset(
        assetPath,
        colorFilter: ColorFilter.mode(
          isActive ? Colors.green : Colors.white,
          BlendMode.srcIn,
        ),
        width: 28, // Reduced from 40
        height: 28, // Reduced from 40
      ),
      iconSize: 28, // Reduced from 40
      onPressed: onPressed,
    );
  }

  Widget _buildLyricsDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      height: 120,
      child: StreamBuilder<Duration>(
        stream: ref.read(musicServiceProvider).positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;

          // Find current line based on position
          int currentLineIndex = _parsedLyrics.isEmpty
              ? -1
              : _parsedLyrics.indexWhere((line) => line.timestamp > position);
          if (currentLineIndex == -1) {
            currentLineIndex =
                _parsedLyrics.isEmpty ? -1 : _parsedLyrics.length - 1;
          } else {
            currentLineIndex = (currentLineIndex - 1)
                .clamp(0, _parsedLyrics.isEmpty ? 0 : _parsedLyrics.length - 1);
          }

          // Find current word
          String? currentWord;
          if (currentLineIndex >= 0 &&
              currentLineIndex < _parsedLyrics.length) {
            final currentLine = _parsedLyrics[currentLineIndex];
            final wordIndex = currentLine.words
                .indexWhere((word) => word.timestamp > position);
            if (wordIndex > 0) {
              currentWord = currentLine.words[wordIndex - 1].text;
            }
          }

          if (_parsedLyrics.isEmpty) {
            return Center(
              child: Text(
                'No lyrics available',
                style: GoogleFonts.lato(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              final lineIndex = (currentLineIndex - 1 + index)
                  .clamp(0, _parsedLyrics.length - 1);
              final line = _parsedLyrics[lineIndex];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: line.words.map((word) {
                      final isCurrentWord = word.text == currentWord;
                      final isCurrentLine = lineIndex == currentLineIndex;

                      return TextSpan(
                        text: '${word.text} ',
                        style: GoogleFonts.lato(
                          color: isCurrentWord
                              ? Colors.green
                              : isCurrentLine
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                          fontSize: isCurrentLine ? 16 : 14,
                          fontWeight: isCurrentWord
                              ? FontWeight.bold
                              : isCurrentLine
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current song to update UI when it changes
    final currentSong = ref.watch<Map<String, dynamic>?>(currentSongProvider);
    final playerState = ref.watch(playerStateProvider);
    final position = ref.watch(positionStreamProvider);
    final duration = ref.watch(durationStreamProvider);
    final controls = ref.watch(playerControlsProvider);

    // Listen to song changes to update palette
    ref.listen<Map<String, dynamic>?>(currentSongProvider, (previous, next) {
      if (next != null && next != previous) {
        _loadImagePalette();
      }
    });

    if (currentSong == null) return const SizedBox.shrink();

    final dominantColor = _palette?.dominantColor?.color ?? Colors.purple;
    final textColor = Colors.white;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0C0F14),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              Icon(Icons.keyboard_arrow_down, color: textColor),
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
                        const SizedBox(width: 48), // Balance the layout
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: _buildAlbumArt(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentSong['title'] ?? '',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentSong['artist'] ?? '',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                              onPressed: ref
                                                  .read(musicServiceProvider)
                                                  .clearQueue,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: StreamBuilder<
                                            List<Map<String, dynamic>>>(
                                          stream: ref
                                              .read(musicServiceProvider)
                                              .queueStream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              print(
                                                  'Queue stream error: ${snapshot.error}');
                                              return Center(
                                                  child: Text(
                                                      'Error loading queue'));
                                            }

                                            if (!snapshot.hasData) {
                                              print('No queue data available');
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }

                                            final queue = snapshot.data!;
                                            print(
                                                'Queue length in UI: ${queue.length}');

                                            if (queue.isEmpty) {
                                              return Center(
                                                  child: Text('Queue is empty',
                                                      style: TextStyle(
                                                          color: Colors.grey)));
                                            }

                                            return ReorderableListView.builder(
                                              itemCount: queue.length,
                                              onReorder: (oldIndex, newIndex) {
                                                ref
                                                    .read(musicServiceProvider)
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
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.playlist_add,
                                          color: Colors.white),
                                      title: Text(
                                        'Add to Playlist',
                                        style: GoogleFonts.lato(
                                            color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showPlaylistSelector(
                                            context, currentSong);
                                      },
                                    ),
                                    ListTile(
                                      leading: FutureBuilder<bool>(
                                        future: ref
                                            .read(musicServiceProvider)
                                            .isSongDownloaded(
                                                currentSong?['id'] ?? ''),
                                        builder: (context, snapshot) {
                                          final isDownloaded =
                                              snapshot.data ?? false;
                                          return StreamBuilder<
                                              Map<String, double>>(
                                            stream: ref
                                                .read(musicServiceProvider)
                                                .downloadProgressStream,
                                            builder:
                                                (context, progressSnapshot) {
                                              final progress =
                                                  progressSnapshot.data?[
                                                          currentSong?['id']] ??
                                                      0.0;
                                              final isDownloading = ref
                                                  .read(musicServiceProvider)
                                                  .isDownloading(
                                                      currentSong?['id'] ?? '');

                                              if (isDownloaded) {
                                                return Icon(Icons.download_done,
                                                    color: Colors.green);
                                              }

                                              if (isDownloading) {
                                                return Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      value: progress,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                      strokeWidth: 2,
                                                    ),
                                                    Text(
                                                      '${(progress * 100).toInt()}%',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 8,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              return Icon(Icons.download,
                                                  color: Colors.white);
                                            },
                                          );
                                        },
                                      ),
                                      title: Text(
                                        'Download',
                                        style: GoogleFonts.lato(
                                            color: Colors.white),
                                      ),
                                      onTap: () async {
                                        if (currentSong == null) return;

                                        try {
                                          final isDownloaded = await ref
                                              .read(musicServiceProvider)
                                              .isSongDownloaded(
                                                  currentSong!['id']);

                                          if (!isDownloaded) {
                                            // Ensure all required fields are present
                                            final songToDownload = {
                                              ...currentSong!,
                                              'audio_url':
                                                  currentSong!['audio_url'],
                                              'album_id':
                                                  currentSong!['album_id'],
                                              'album_title':
                                                  currentSong!['album_title'] ??
                                                      '',
                                              'image_url':
                                                  currentSong!['image_url'],
                                              'album_image_url': currentSong![
                                                      'album_image_url'] ??
                                                  currentSong!['image_url'],
                                            };

                                            // Close the modal bottom sheet
                                            Navigator.pop(context);

                                            // Start download
                                            await ref
                                                .read(musicServiceProvider)
                                                .downloadSong(songToDownload);

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Download started'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          } else {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Song already downloaded'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Download failed: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: StreamBuilder<Duration>(
                      stream: ref.read(musicServiceProvider).positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration?>(
                          stream: ref.read(musicServiceProvider).durationStream,
                          builder: (context, snapshot) {
                            final duration = snapshot.data ?? Duration.zero;
                            return _buildProgressBar(
                                position, duration, textColor);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          'assets/icons/shuffle.svg',
                          _isShuffleEnabled,
                          () async {
                            final newShuffleState = !_isShuffleEnabled;
                            setState(() {
                              _isShuffleEnabled = newShuffleState;
                            });
                            await ref
                                .read(musicServiceProvider)
                                .setShuffleMode(newShuffleState);
                            if (newShuffleState) {
                              await ref
                                  .read(musicServiceProvider)
                                  .shuffleQueue();
                            } else {
                              await ref
                                  .read(musicServiceProvider)
                                  .restoreOriginalQueue();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: textColor),
                          iconSize: 40, // Reduced from 50
                          onPressed:
                              ref.read(musicServiceProvider).playPrevious,
                        ),
                        StreamBuilder<PlayerState>(
                          stream:
                              ref.read(musicServiceProvider).playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing;

                            if (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return Container(
                                margin: const EdgeInsets.all(8.0),
                                width: 50.0,
                                height: 50.0,
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
                              iconSize: 56, // Reduced from 60
                              onPressed: playing == true
                                  ? ref.read(musicServiceProvider).pause
                                  : ref.read(musicServiceProvider).resume,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: textColor),
                          iconSize: 40, // Reduced from 50
                          onPressed: ref.read(musicServiceProvider).playNext,
                        ),
                        _buildControlButton(
                          'assets/icons/repeat.svg',
                          _loopMode != LoopMode.off,
                          () {
                            ref
                                .read(musicServiceProvider)
                                .cycleLoopMode()
                                .then((_) {
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
                  _buildLyricsDisplay(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistSelectorSheet(
        song: {
          ...song,
          'title': song['title'] ?? 'Unknown Title',
          'artist': song['artist'] ?? 'Unknown Artist',
          'image_url': song['image_url'] ?? '',
          'audio_url': song['audio_url'] ?? '',
          'id': song['id'],
        },
        musicService: ref.read(musicServiceProvider),
      ),
    );
  }

  Future<String?> _getLyricsForPosition(
      String songId, Duration position) async {
    try {
      final response = await Supabase.instance.client
          .from('songs')
          .select('song_lyrics')
          .eq('id', songId)
          .single();

      if (response == null || response['song_lyrics'] == null) {
        return null;
      }

      final lyrics = response['song_lyrics'] as String;
      final lines = lyrics.split('\n');

      // For now, return a static line based on position
      // In a real implementation, you would parse timestamps and return the appropriate line
      final currentLineIndex = (position.inSeconds % lines.length);
      return lines[currentLineIndex];
    } catch (e) {
      print('Error fetching lyrics: $e');
      return null;
    }
  }
}
