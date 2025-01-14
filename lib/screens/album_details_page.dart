import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:palette_generator/palette_generator.dart';
import '../widgets/floating_player_mixin.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'library_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
  bool _isDownloadingAlbum = false;
  double _downloadProgress = 0.0;

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

  Future<void> _downloadAllSongs() async {
    if (_isDownloadingAlbum) return;

    setState(() {
      _isDownloadingAlbum = true;
      _downloadProgress = 0.0;
    });

    try {
      final songs = await _songsFuture;
      final totalSongs = songs.length;
      int downloadedSongs = 0;

      for (var song in songs) {
        try {
          if (!(await widget.musicService.isSongDownloaded(song['id']))) {
            final songToDownload = {
              ...song,
              'album_title': widget.album['title'],
            };
            await widget.musicService.downloadSong(songToDownload);
          }
          downloadedSongs++;
          setState(() {
            _downloadProgress = downloadedSongs / totalSongs;
          });
        } catch (e) {
          print('Error downloading song: $e');
          // Continue with next song even if one fails
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All songs downloaded successfully!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download some songs: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isDownloadingAlbum = false;
        _downloadProgress = 0.0;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
                          Hero(
                            tag: 'album_image_${widget.album['id']}',
                            child: Container(
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
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'album_title_${widget.album['id']}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      widget.album['title'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                      child: Row(
                        children: [
                          Expanded(
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
                          SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: widget.musicService.getAlbumDownloadState(widget.album['id']),
                                builder: (context, snapshot) {
                                  final downloadState = snapshot.data ?? {
                                    'isDownloading': false,
                                    'isFullyDownloaded': false,
                                    'progress': 0.0,
                                  };

                                  final isDownloading = downloadState['isDownloading'] ?? false;
                                  final isFullyDownloaded = downloadState['isFullyDownloaded'] ?? false;
                                  final progress = downloadState['progress'] ?? 0.0;

                                  if (isFullyDownloaded) {
                                    return Center(
                                      child: Icon(
                                        Icons.download_done_rounded,
                                        color: Colors.green[400],
                                        size: 24,
                                      ),
                                    );
                                  }

                                  if (isDownloading) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[800],
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                        Text(
                                          '${(progress * 100).toInt()}%',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: _downloadAllSongs,
                                    child: Center(
                                      child: Icon(
                                        Icons.download_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Title',
                              style: TextStyle(color: themeProvider.getPrimaryTextColor()),
                            ),
                          ),
                          Text(
                            'Duration',
                            style: TextStyle(color: themeProvider.getPrimaryTextColor()),
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
              onTap: (index) {
                // First notify parent of index change
                widget.onIndexChanged(index);
                // Then pop back to parent if index is different
                if (index != widget.selectedIndex) {
                  Navigator.of(context).pop();
                }
              },
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
                // BottomNavigationBarItem(
                //   icon: SvgPicture.asset(
                //     'assets/icons/profile_icon.svg',
                //     colorFilter: ColorFilter.mode(
                //       widget.selectedIndex == 3 ? Colors.white : Colors.grey,
                //       BlendMode.srcIn,
                //     ),
                //   ),
                //   label: 'Profile',
                // ),
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
  final String songId;  // Add this
  final MusicService musicService;  // Add this

  const DownloadButton({
    Key? key,
    required this.isDownloaded,
    required this.onPressed,
    required this.songId,  // Add this
    required this.musicService,  // Add this
  }) : super(key: key);

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _downloadedScale;
  
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: widget.musicService.downloadProgressStream,
      builder: (context, snapshot) {
        return FutureBuilder<bool>(
          future: widget.musicService.isSongDownloaded(widget.songId),
          builder: (context, downloadedSnapshot) {
            final isDownloaded = downloadedSnapshot.data ?? widget.isDownloaded;
            final isDownloading = widget.musicService.isDownloading(widget.songId);
            final downloadProgress = snapshot.data?[widget.songId] ?? 0.0;

            // Show completed download icon
            if (isDownloaded) {
              return ScaleTransition(
                scale: _downloadedScale,
                child: Icon(
                  Icons.download_done_rounded,
                  color: Colors.green[400],
                  size: 24,
                ),
              );
            }

            // Show progress indicator while downloading
            if (isDownloading) {
              return SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                    if (downloadProgress > 0)
                      Text(
                        '${(downloadProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }

            // Show download button
            return IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
              onPressed: () async {
                await widget.onPressed();
                _controller.forward();
              },
            );
          },
        );
      },
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

  Widget _buildSongImage(Map<String, dynamic> song) {
    return FutureBuilder<String?>(
      future: musicService.getCachedImagePath(song['id']),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Use cached image
          return Container(
            width: 50,  // Increased from 40
            height: 50,  // Increased from 40
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
            width: 50,  // Increased from 40
            height: 50,  // Increased from 40
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

  void _showMoreOptions(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.playlist_add, color: Colors.white),
              title: Text(
                'Add to Playlist',
                style: GoogleFonts.lato(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showPlaylistSelector(context, song);
              },
            ),
            // Add more options here
          ],
        ),
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistSelectorSheet(
        song: song,
        musicService: musicService,
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, Map<String, dynamic> song) {
    return FutureBuilder<bool>(
      key: ValueKey('download_${song['id']}'), // Remove timestamp to prevent rebuilds
      future: musicService.isSongDownloaded(song['id']),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;
        
        return DownloadButton(
          isDownloaded: isDownloaded,
          onPressed: () async {
            final songToDownload = {
              ...song,
              'album_title': album['title'],
            };
            await musicService.downloadSong(songToDownload);
          },
          songId: song['id'],  // Add this
          musicService: musicService,  // Add this
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = songs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildSongImage(song), // Directly use _buildSongImage here
                title: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'],
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        song['artist'],
                        style: GoogleFonts.lato(  // Changed this line
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
                    Text(
                      song['duration'] ?? '0:00',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                      ),
                      onPressed: () => _showMoreOptions(context, song),
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
                      // Use song's image_url if available, fallback to album image
                      'image_url': song['image_url'] ?? album['image_url'],
                      'title': song['title'] ?? 'Unknown Title',
                      'artist': song['artist'] ?? 'Unknown Artist',
                      'audio_url': audioUrl,
                    };

                    // Get subsequent songs
                    final subsequentSongs = songs
                        .skip(index + 1)
                        .map((s) => {
                              ...s,
                              // Only use album image as fallback
                              'image_url': s['image_url'] ?? album['image_url'],
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
              ),
            ),
          );
        },
        childCount: songs.length,
      ),
    );
  }
}

class PlaylistSelectorSheet extends StatefulWidget {
  final Map<String, dynamic> song;
  final MusicService musicService;

  const PlaylistSelectorSheet({
    Key? key,
    required this.song,
    required this.musicService,
  }) : super(key: key);

  @override
  State<PlaylistSelectorSheet> createState() => _PlaylistSelectorSheetState();
}

class _PlaylistSelectorSheetState extends State<PlaylistSelectorSheet> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _playlistsFuture = widget.musicService.getUserPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Add to Playlist',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              width: 50,  // Increased from 40
              height: 50,  // Increased from 40
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
            title: Text(
              'Create New Playlist',
              style: GoogleFonts.lato(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePlaylistScreen(),
                ),
              );
              if (result == true) {
                // Refresh playlists
                setState(() {
                  _playlistsFuture = widget.musicService.getUserPlaylists();
                });
              }
            },
          ),
          Divider(color: Colors.grey[800]),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _playlistsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No playlists found',
                    style: GoogleFonts.lato(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final playlist = snapshot.data![index];
                  return ListTile(
                    leading: Container(
                      width: 50,  // Increased from 40
                      height: 50,  // Increased from 40
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: playlist['image_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(playlist['image_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: playlist['image_url'] == null
                          ? Icon(Icons.music_note, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      playlist['playlist_name'],
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    onTap: () async {
                      try {
                        await widget.musicService.addSongToPlaylist(
                          playlist['id'],
                          widget.song,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${playlist['playlist_name']}'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add song: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
