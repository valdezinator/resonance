import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:palette_generator/palette_generator.dart';
import '../widgets/floating_player_mixin.dart';
import 'dart:ui';
import 'dart:io';

class AlbumDetailsPage extends StatefulWidget {
  final Map<String, dynamic> album;
  final MusicService musicService;
  final Function(Map<String, dynamic>) onSongPlay;
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final Map<String, dynamic>? currentSong;

  const AlbumDetailsPage({
    Key? key,
    required this.album,
    required this.musicService,
    required this.onSongPlay,
    required this.selectedIndex,
    required this.onIndexChanged,
    this.currentSong,
  }) : super(key: key);

  @override
  State<AlbumDetailsPage> createState() => _AlbumDetailsPageState();
}

class _AlbumDetailsPageState extends State<AlbumDetailsPage> with FloatingPlayerMixin {
  Map<String, dynamic>? _localCurrentSong;
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _allSongs = [];
  List<Map<String, dynamic>> _filteredSongs = [];
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _localCurrentSong = widget.currentSong;
    _loadAlbumSongs();
  }

  Future<void> _loadAlbumSongs() async {
    try {
      _songsFuture = widget.musicService.getAlbumSongs(widget.album['id']);
      final songs = await _songsFuture;
      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
      });
    } catch (e) {
      print('Error loading songs: $e');
      // Try to load downloaded songs for this album
      final downloadedSongs = 
          await widget.musicService.getDownloadedSongsForAlbum(widget.album['id']);
      setState(() {
        _allSongs = downloadedSongs;
        _filteredSongs = downloadedSongs;
      });
    }
  }

  void _filterSongs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSongs = _allSongs;
      } else {
        _filteredSongs = _allSongs
            .where((song) =>
                song['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
                song['artist'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void didUpdateWidget(AlbumDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSong != oldWidget.currentSong) {
      setState(() {
        _localCurrentSong = widget.currentSong;
      });
    }
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '0:00';

    try {
      final seconds = int.parse(duration.toString());
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return duration.toString(); // Return the original value if parsing fails
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14),
      body: Stack(
        children: [
          Container(
            // decoration: BoxDecoration(
            //   gradient: RadialGradient(
            //     center: Alignment(0, -0.5),
            //     radius: 1.5,
            //     colors: [
            //       dominantColor.withOpacity(0.3),
            //       dominantColor.withOpacity(0.1),
            //       const Color(0xFF0C0F14),
            //     ],
            //     stops: const [0.0, 0.4, 1.0],
            //   ),
            // ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _songsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _allSongs.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && _allSongs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unable to load songs',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Try to load downloaded songs for this album
                          try {
                            final downloadedSongs = 
                                await widget.musicService.getDownloadedSongsForAlbum(widget.album['id']);
                            setState(() {
                              _allSongs = downloadedSongs;
                              _filteredSongs = downloadedSongs;
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No downloaded songs available')),
                            );
                          }
                        },
                        child: Text('Show Downloaded Songs'),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 60,
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    leading: IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isSearching) {
                              _isSearching = false;
                              _searchController.clear();
                              _filterSongs('');
                            } else {
                              _isSearching = true;
                            }
                          });
                        },
                      ),
                    ],
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search songs...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onChanged: _filterSongs,
                          )
                        : null,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 0,
                        bottom: 16.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.album['image_url'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.album['title'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.album['artist'],
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final songs = await widget.musicService
                                .getAlbumSongs(widget.album['id']);

                            if (songs.isNotEmpty) {
                              widget.onSongPlay({
                                ...songs[0],
                                'image_url': widget.album['image_url'],
                              });

                              await widget.musicService.playAllSongs(songs);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to play album: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: Size(120, 48),
                        ),
                        child: Text(
                          'Play All',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '#',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Title',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Text(
                            'Duration',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _SongListView(
                    songs: _filteredSongs, // Use filtered songs instead of all songs
                    album: widget.album,
                    musicService: widget.musicService,
                    onSongPlay: widget.onSongPlay,
                    onLocalSongUpdate: (songData) {
                      setState(() {
                        _localCurrentSong = songData;
                      });
                    },
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              );
            },
          ),
          buildFloatingBottomPlayer(
            currentSong: _localCurrentSong,
            musicService: widget.musicService,
            onSongPlay: (song) {
              if (song != null) {
                setState(() {
                  _localCurrentSong = song;
                });
                widget.onSongPlay(song);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.grey.withOpacity(0.6),
              currentIndex: widget.selectedIndex,
              type: BottomNavigationBarType.fixed,
              onTap: widget.onIndexChanged,
              items: [
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/icons/home_icon.svg',
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 0 ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/icons/search_icon.svg',
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 1 ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/icons/library_icon.svg',
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 2 ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                    'assets/icons/profile_icon.svg',
                    colorFilter: ColorFilter.mode(
                      widget.selectedIndex == 3 ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadButton extends StatefulWidget {
  final bool isDownloaded;
  final Function() onPressed;

  const DownloadButton({
    Key? key,
    required this.isDownloaded,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _downloadedScale;
  bool _isDownloading = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _downloadedScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDownload() async {
    setState(() => _isDownloading = true);
    _controller.repeat();
    
    await widget.onPressed();
    
    _controller.stop();
    setState(() => _isDownloading = false);
    
    // Add completion animation
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDownloaded) {
      return ScaleTransition(
        scale: _downloadedScale,
        child: IconButton(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[400],
                size: 24,
              ),
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[400]?.withOpacity(0.5),
                size: 28,
              ),
            ],
          ),
          onPressed: null,
        ),
      );
    }

    if (_isDownloading) {
      return Container(
        width: 48,
        height: 48,
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.download_rounded,
        color: Colors.grey[400],
        size: 24,
      ),
      onPressed: _startDownload,
    );
  }
}

class _SongListView extends StatelessWidget {
  final List<Map<String, dynamic>> songs;
  final Map<String, dynamic> album;
  final MusicService musicService;
  final Function(Map<String, dynamic>) onSongPlay;
  final Function(Map<String, dynamic>) onLocalSongUpdate;

  const _SongListView({
    Key? key,
    required this.songs,
    required this.album,
    required this.musicService,
    required this.onSongPlay,
    required this.onLocalSongUpdate,
  }) : super(key: key);

  Widget _buildDownloadButton(BuildContext context, Map<String, dynamic> song) {
    return FutureBuilder<bool>(
      // Add key to force rebuild when download state changes
      key: ValueKey('download_${song['id']}_${DateTime.now().millisecondsSinceEpoch}'),
      future: musicService.isSongDownloaded(song['id']),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        
        return DownloadButton(
          isDownloaded: isDownloaded,
          onPressed: () async {
            try {
              // Show downloading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Downloading ${song['title']}...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );

              final songToDownload = {
                ...song,
                'image_url': album['image_url'],
                'album_title': album['title'],
              };
              
              await musicService.downloadSong(songToDownload);

              // Force a rebuild of the entire list tile
              (context as Element).markNeedsBuild();

              // Add a slight delay before showing success message to ensure UI updates
              await Future.delayed(Duration(milliseconds: 100));

              // Show success message
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[400]),
                        SizedBox(width: 12),
                        Text('Downloaded successfully'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[400]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Download failed: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSongImage(Map<String, dynamic> song) {
    return FutureBuilder<String?>(
      future: musicService.getCachedImagePath(song['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Use cached image
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: FileImage(File(snapshot.data!)),
                fit: BoxFit.cover,
              ),
            ),
          );
        } else {
          // Use network image or album image
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(song['image_url'] ?? album['image_url']),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = songs[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                _buildSongImage(song),
              ],
            ),
            title: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    song['artist'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            subtitle: null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDownloadButton(context, song),
                Text(
                  song['duration'] ?? '0:00',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            onTap: () async {
              try {
                final audioUrl = song['audio_url'];
                if (audioUrl == null || audioUrl.isEmpty) {
                  throw Exception('Song URL is missing');
                }

                final songData = {
                  ...song,
                  'id': song['id'],
                  'image_url': album['image_url'],
                  'title': song['title'] ?? 'Unknown Title',
                  'artist': song['artist'] ?? 'Unknown Artist',
                  'audio_url': audioUrl,
                };

                // Get subsequent songs
                final subsequentSongs = songs
                    .skip(index + 1)
                    .map((s) => {
                          ...s,
                          'image_url': album['image_url'],
                        })
                    .toList();

                // Update local state first
                onLocalSongUpdate(songData);

                // Then update parent state
                onSongPlay(songData);

                // Finally play the song with subsequent songs in queue
                await musicService.playSong(
                  audioUrl,
                  currentSong: songData,
                  subsequentSongs: subsequentSongs,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to play song: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        },
        childCount: songs.length,
      ),
    );
  }
}
