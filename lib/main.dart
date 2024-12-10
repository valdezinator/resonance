import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/music_service.dart';
import 'widgets/bottom_player.dart';
import 'config/supabase_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/search_page.dart';
import 'screens/settings_page.dart';
import 'screens/album_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'screens/artist_details_page.dart';
import 'widgets/full_screen_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // scaffoldBackgroundColor: Colors.black,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MusicService _musicService = MusicService();
  Map<String, dynamic>? currentSong;
  late Future<List<Map<String, dynamic>>> _songsFuture;
  late Future<List<Map<String, dynamic>>> _albumsFuture;
  late Future<List<Map<String, dynamic>>> _artistsFuture;
  late Future<List<Map<String, dynamic>>> _recentlyPlayedFuture;
  late Future<List<Map<String, dynamic>>> _personalizedPlaylistsFuture;
  late Future<List<Map<String, dynamic>>> _topChartsFuture;
  int _selectedIndex = 0;
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;
  List<Map<String, dynamic>> _songs = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadMoreSongs();
    _albumsFuture = _musicService.getAlbums();
    _artistsFuture = _musicService.getRecommendedArtists();
    _recentlyPlayedFuture = _musicService.getRecentlyPlayed();
    _personalizedPlaylistsFuture = _musicService.getPersonalizedPlaylists();
    _topChartsFuture = _musicService.getTopCharts();
  }

  Future<void> _loadMoreSongs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newSongs = await _musicService.getQuickPlaySongs(
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );

      setState(() {
        _songs.addAll(newSongs);
        _currentPage++;
        _hasMore = newSongs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      // Handle error
    }
  }

  Widget _buildFloatingBottomPlayer() {
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
            key: ValueKey(currentSong!['id']),
            musicService: _musicService,
            currentSong: currentSong,
            onClose: () {
              setState(() {
                currentSong = null;
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 25, 34),
      // backgroundColor: Colors.white10,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(),
              child: _selectedIndex == 1
                  ? SearchPage(
                      currentSong: currentSong,
                      onSongPlay: (song) {
                        setState(() {
                          currentSong = song;
                        });
                      },
                      musicService: _musicService,
                    )
                  : _selectedIndex == 2
                      ? SettingsPage(
                          currentSong: currentSong,
                          onSongPlay: (song) {
                            setState(() {
                              currentSong = song;
                            });
                          },
                          musicService: _musicService,
                        )
                      : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with greeting
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Good\nmorning Peter✨',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[900],
                                      radius: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Chips row
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Feel Good',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.grey[800],
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text('Party',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.grey[800],
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text('Party',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      backgroundColor: Colors.grey[800],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),

                                // Quick Play section
                                Text(
                                  'Quick Play',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Grid of songs from Supabase
                                _buildSongsList(),

                                SizedBox(height: 24),

                                // Just the Hits section
                                Text(
                                  'Just the Hits',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Albums list
                                SizedBox(
                                  height: 220,
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _albumsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (snapshot.hasError) {
                                        return Text(
                                          'Error loading albums: ${snapshot.error}',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      }

                                      final albums = snapshot.data ?? [];

                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: albums.length,
                                        itemBuilder: (context, index) {
                                          return _buildAlbumTile(albums[index]);
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Recommended Artists section
                                SizedBox(height: 32),

                                // Recommended Artists section
                                Text(
                                  'Recommended Artists',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Artists list
                                SizedBox(
                                  height: 160,
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _artistsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (snapshot.hasError) {
                                        return Text(
                                          'Error loading artists: ${snapshot.error}',
                                          style: TextStyle(color: Colors.red),
                                        );
                                      }

                                      final artists = snapshot.data ?? [];

                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: artists.length,
                                        itemBuilder: (context, index) {
                                          return _buildArtistTile(
                                              artists[index]);
                                        },
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(height: 32),
                                _buildRecentlyPlayed(),

                                SizedBox(height: 32),
                                _buildMadeForYou(),

                                SizedBox(height: 32),
                                _buildTopCharts(),

                                // Bottom navigation bar will be handled separately
                              ],
                            ),
                          ),
                        ),
            ),
            _buildFloatingBottomPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/home_icon.svg',
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 0 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/search_icon.svg',
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 1 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/profile_icon.svg',
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 2 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _musicService.dispose();
    super.dispose();
  }

  Widget _buildSongTile(String title, String artist, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 56,
                height: 56,
                color: Colors.grey[800],
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 56,
                height: 56,
                color: Colors.grey[800],
                child: Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load songs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumTile(Map<String, dynamic> album) {
    return GestureDetector(
      key: ValueKey('album_${album['id']}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailsPage(
              album: album,
              musicService: _musicService,
              onSongPlay: (song) {
                setState(() {
                  currentSong = song;
                });
              },
              selectedIndex: _selectedIndex,
              onIndexChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              currentSong: currentSong,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: album['image_url'] as String,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey[900],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey[900],
                  child: Icon(Icons.album, color: Colors.white, size: 50),
                ),
              ),
            ),
            SizedBox(height: 8),
            // Title
            Text(
              album['title'] as String,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            // Artist
            Text(
              album['artist'] as String,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistTile(Map<String, dynamic> artist) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistDetailsPage(
              artist: artist,
              musicService: _musicService,
              onSongPlay: (song) {
                setState(() {
                  currentSong = song;
                });
              },
              currentSong: currentSong,
            ),
          ),
        );
      },
      child: Container(
        key: ValueKey('artist_${artist['id']}'),
        width: 120,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Artist Image
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: artist['image_url'] as String,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[900],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[900],
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
            SizedBox(height: 8),
            // Artist Name
            Text(
              artist['artist'] as String,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _songs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _songs.length) {
          _loadMoreSongs();
          return Center(child: CircularProgressIndicator());
        }

        final song = _songs[index];
        return GestureDetector(
          onTap: () async {
            try {
              final audioUrl = song['audio_url'] as String?;
              if (audioUrl == null || audioUrl.isEmpty) {
                throw Exception('Song URL is missing');
              }

              setState(() {
                currentSong = song;
              });

              // Get next song from _songs array
              final nextSongIndex = index + 1;
              final nextSong =
                  nextSongIndex < _songs.length ? _songs[nextSongIndex] : null;

              await _musicService.playSong(
                audioUrl,
                currentSong: song,
                nextSong: nextSong,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to play song: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: _buildSongTile(
            song['title'] ?? 'Unknown Title',
            song['artist'] ?? 'Unknown Artist',
            song['image_url'] ?? '',
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Played',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _recentlyPlayedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red));
              }

              final songs = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index]['songs'];
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: song['image_url'],
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          song['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMadeForYou() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Made For You',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _personalizedPlaylistsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final playlists = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.6),
                          Colors.blue.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist['name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            playlist['description'],
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Charts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _topChartsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final charts = snapshot.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: math.min(5, charts.length),
              itemBuilder: (context, index) {
                final song = charts[index]['songs'];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(
                      song['title'],
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song['artist'],
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Icon(Icons.play_circle_filled,
                        color: Colors.white, size: 32),
                    onTap: () {
                      // Handle song play
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
