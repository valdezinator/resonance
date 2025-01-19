import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'services/audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'screens/library_page.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'screens/profile_image_page.dart';
import 'providers/theme_provider.dart';
import 'package:provider/provider.dart' as provider; // Add prefix
import 'animations/page_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../providers/theme_providers.dart';
import 'services/music_service.dart';

final songsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(musicServiceProvider).getQuickPlaySongs();
});

final albumsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(musicServiceProvider).getAlbums();
});

final artistsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(musicServiceProvider).getRecommendedArtists();
});

final personalizedPlaylistsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(musicServiceProvider).getPersonalizedPlaylists();
});

final topChartsFutureProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(musicServiceProvider).getTopCharts();
});

class MyApp extends ConsumerWidget {
  final User? user;

  const MyApp({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0C0F14),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _profileImagePath;
  int _selectedIndex = 0;
  static const int _pageSize = 10;
  int _currentPage = 0;
  bool _hasMore = true;
  List<Map<String, dynamic>> _songs = [];
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image');
    });
  }

  Future<void> _initServices() async {
    try {
      await ref.read(musicServiceProvider).init();
      _loadMoreSongs();
      // Refresh all future providers
      ref.refresh(songsFutureProvider);
      ref.refresh(albumsFutureProvider);
      ref.refresh(artistsFutureProvider);
      ref.refresh(personalizedPlaylistsFutureProvider);
      ref.refresh(topChartsFutureProvider);
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Future<void> main() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    runApp(HomePage());
  }

  Future<void> _loadMoreSongs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // First try to get from network
      final newSongs = await ref.read(musicServiceProvider).getQuickPlaySongs(
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
      // If network fails, load downloaded songs
      final downloadedSongs =
          await ref.read(musicServiceProvider).getDownloadedSongs();

      setState(() {
        _songs = downloadedSongs;
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _playSong(Map<String, dynamic> song, int index) async {
    try {
      final audioUrl = song['audio_url'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) {
        throw Exception('Song URL is missing');
      }

      // Update current song using the provider
      ref.read(currentSongProvider.notifier).updateCurrentSong(song);

      // Get next song from _songs array
      final nextSongIndex = index + 1;
      final nextSong =
          nextSongIndex < _songs.length ? _songs[nextSongIndex] : null;

      await ref.read(musicServiceProvider).playSong(
            audioUrl,
            currentSong: song,
            subsequentSongs: nextSong != null ? [nextSong] : null,
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
  }

  Widget _buildFloatingBottomPlayer() {
    final currentSong = ref.watch(currentSongProvider);
    if (currentSong == null) return const SizedBox.shrink();

    return Positioned(
      left: 2,
      right: 2,
      bottom: 5,
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(12),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(0.3),
        //       blurRadius: 10,
        //       offset: Offset(0, 5),
        //     ),
        //   ],
        // ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BottomPlayer(
            key: ValueKey(currentSong['id']),
            currentSong: currentSong,
            onClose: () {
              ref.read(currentSongProvider.notifier).updateCurrentSong(null);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      // backgroundColor: Colors.white10,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(),
              child: _selectedIndex == 1
                  ? SearchPage(
                      currentSong: ref.watch(currentSongProvider),
                      onSongPlay: (song) {
                        ref
                            .read(currentSongProvider.notifier)
                            .updateCurrentSong(song);
                      },
                      musicService: ref.read(musicServiceProvider),
                      selectedIndex: _selectedIndex,
                      onIndexChanged: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    )
                  : _selectedIndex == 2
                      ? LibraryPage(
                          selectedIndex: _selectedIndex,
                          onNavigate: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          onIndexChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        )
                      : _selectedIndex == 3
                          ? ProfileImagePage(
                              musicService: ref.read(musicServiceProvider),
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
                                          'Good morning,\n Peter✨',
                                          // style: TextStyle(
                                          //   color: Colors.white,
                                          //   fontSize: 24,
                                          //   fontWeight: FontWeight.bold,
                                          // ),
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileImagePage(
                                                  musicService: ref.read(
                                                      musicServiceProvider),
                                                ),
                                              ),
                                            ).then((_) => _loadProfileImage());
                                          },
                                          child: CircleAvatar(
                                            radius: 20,
                                            backgroundImage:
                                                _profileImagePath != null
                                                    ? FileImage(File(
                                                        _profileImagePath!))
                                                    : null,
                                            child: _profileImagePath == null
                                                ? Icon(Icons.person,
                                                    color: Colors.white)
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Chips row
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text('Feel Good',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          backgroundColor: Colors.grey[800],
                                        ),
                                        SizedBox(width: 8),
                                        Chip(
                                          label: Text('Party',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          backgroundColor: Colors.grey[800],
                                        ),
                                        SizedBox(width: 8),
                                        Chip(
                                          label: Text('Party',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          backgroundColor: Colors.grey[800],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),

                                    // Quick Play section
                                    Text(
                                      'Quick Play',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 16),

                                    // Grid of songs from Supabase
                                    _buildSongsList(),

                                    SizedBox(height: 24),

                                    // Just the Hits section
                                    Text(
                                      'Just the Hits',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 16),

                                    // Albums list
                                    SizedBox(
                                      height: 220,
                                      child: ref
                                          .watch(albumsFutureProvider)
                                          .when(
                                            data: (albums) => ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: albums.length,
                                              itemBuilder: (context, index) {
                                                return _buildAlbumTile(
                                                    albums[index]);
                                              },
                                            ),
                                            loading: () => Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            error: (error, stack) => Text(
                                                'Error loading albums: $error'),
                                          ),
                                    ),

                                    // Recommended Artists section
                                    SizedBox(height: 32),

                                    // Recommended Artists section
                                    Text(
                                      'Recommended Artists',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 16),

                                    // Artists list
                                    SizedBox(
                                      height: 160,
                                      child: ref
                                          .watch(artistsFutureProvider)
                                          .when(
                                            data: (artists) => ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: artists.length,
                                              itemBuilder: (context, index) {
                                                return _buildArtistTile(
                                                    artists[index]);
                                              },
                                            ),
                                            loading: () => Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            error: (error, stack) => Text(
                                                'Error loading artists: $error'),
                                          ),
                                    ),

                                    SizedBox(height: 32),
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
                    'assets/icons/library_icon.svg',
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 2 ? Colors.white : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Library',
                ),
                // BottomNavigationBarItem(
                //   icon: SvgPicture.asset(
                //     'assets/icons/profile_icon.svg',
                //     colorFilter: ColorFilter.mode(
                //       _selectedIndex == 3 ? Colors.white : Colors.grey,
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

  // void _myEntrypoint() => AudioServiceBackground.run(() => MyBackgroundTask());

  @override
  void dispose() {
    ref.read(musicServiceProvider).dispose();
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
                  style: GoogleFonts.lato(
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: GoogleFonts.lato(
                    color: Colors.white,
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
          SlideUpPageRoute(
            child: AlbumDetailsPage(
              album: album,
              musicService: ref.read(musicServiceProvider),
              onSongPlay: (song) {
                ref.read(currentSongProvider.notifier).updateCurrentSong(song);
              },
              selectedIndex: _selectedIndex,
              onIndexChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              currentSong: ref.watch(currentSongProvider),
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
            // Album Cover with Hero animation
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: 'album_image_${album['id']}',
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
            ),
            SizedBox(height: 8),
            // Title with Material
            Material(
              color: Colors.transparent,
              child: Text(
                album['title'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
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
              musicService: ref.read(musicServiceProvider),
              onSongPlay: (song) {
                ref.read(currentSongProvider.notifier).updateCurrentSong(song);
              },
              currentSong: ref.watch(currentSongProvider),
              selectedIndex: _selectedIndex,
              onIndexChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
    return ref.watch(songsFutureProvider).when(
          data: (songs) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: songs.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= songs.length) {
                _loadMoreSongs();
                return Center(child: CircularProgressIndicator());
              }

              final song = songs[index];
              return GestureDetector(
                onTap: () => _playSong(song, index),
                child: _buildSongTile(
                  song['title'] ?? 'Unknown Title',
                  song['artist'] ?? 'Unknown Artist',
                  song['image_url'] ?? '',
                ),
              );
            },
          ),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
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
          child: ref.watch(personalizedPlaylistsFutureProvider).when(
                data: (playlists) => ListView.builder(
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
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error: $error'),
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
        ref.watch(topChartsFutureProvider).when(
              data: (charts) => Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
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
                ),
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
      ],
    );
  }
}
