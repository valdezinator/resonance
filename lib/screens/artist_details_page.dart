import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Add this import
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    
    // Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0c0f14),
    );

    void drawGlowingBlob(Offset center, double radius, Color color, double opacity) {
      final path = Path();
      final rnd = math.Random();
      
      const spikes = 6;
      const step = 2 * math.pi / spikes;
      
      for (var i = 0; i < spikes; i++) {
        final angle = i * step;
        final nextAngle = (i + 1) * step;
        
        final radiusOffset = radius * (0.8 + 0.4 * rnd.nextDouble());
        final nextRadiusOffset = radius * (0.8 + 0.4 * rnd.nextDouble());
        
        final x1 = center.dx + radiusOffset * math.cos(angle);
        final y1 = center.dy + radiusOffset * math.sin(angle);
        
        final x2 = center.dx + nextRadiusOffset * math.cos(nextAngle);
        final y2 = center.dy + nextRadiusOffset * math.sin(nextAngle);
        
        if (i == 0) {
          path.moveTo(x1, y1);
        }
        
        final controlX = center.dx + radius * 1.5 * math.cos((angle + nextAngle) / 2);
        final controlY = center.dy + radius * 1.5 * math.sin((angle + nextAngle) / 2);
        
        path.quadraticBezierTo(controlX, controlY, x2, y2);
      }
      
      path.close();

      // Draw outer glow
      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..shader = RadialGradient(
          center: const Alignment(0.0, 0.0),
          radius: 1.0,
          colors: [
            color.withOpacity(opacity * 0.8),
            color.withOpacity(0),
          ],
          stops: const [0.2, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2));
      
      canvas.drawPath(path, glowPaint);

      // Draw inner blob
      final blobPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, 0.0),
          radius: 1.0,
          colors: [
            color.withOpacity(opacity * 0.4),
            color.withOpacity(opacity * 0.1),
          ],
          stops: const [0.2, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
      
      canvas.drawPath(path, blobPaint);
    }

    // Draw multiple glowing blobs with different sizes and positions
    final blobConfigs = [
      {'x': 0.2, 'y': 0.1, 'radius': 150.0, 'color': const Color(0xFF945e5c), 'opacity': 0.7},
      {'x': 0.8, 'y': 0.15, 'radius': 180.0, 'color': const Color(0xFF145362), 'opacity': 0.6},
    ];

    for (final config in blobConfigs) {
      drawGlowingBlob(
        Offset(size.width * (config['x'] as double), size.height * (config['y'] as double)),
        config['radius'] as double,
        config['color'] as Color,
        config['opacity'] as double,
      );
    }
  }

  @override
  bool shouldRepaint(BlobPainter oldDelegate) => false;
}

class ArtistDetailsPage extends StatefulWidget {
  final Map<String, dynamic> artist;
  final MusicService musicService;
  final Function(Map<String, dynamic>?) onSongPlay;
  final Map<String, dynamic>? currentSong;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const ArtistDetailsPage({
    Key? key,
    required this.artist,
    required this.musicService,
    required this.onSongPlay,
    this.currentSong,
    required this.selectedIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends State<ArtistDetailsPage>
    with FloatingPlayerMixin {
  Map<String, dynamic>? artistData;
  bool showFullDetails = false;
  List<Map<String, dynamic>> topSongs = [];  // Add this line
  List<Map<String, dynamic>> albums = [];  // Add this line

  @override
  void initState() {
    super.initState();
    print('Artist data from recommended_artists: ${widget.artist}'); // Debug log
    loadArtistData();
    loadTopSongs();  // Add this line
    loadAlbums();  // Add this line
  }

  // Add this method
  Future<void> loadTopSongs() async {
    try {
      // Get the artist name and ensure it's a non-null string
      final String artistName = widget.artist['artist']?.toString() ?? '';
      print('Attempting to load top songs for artist: "$artistName"');
      
      if (artistName.isEmpty) {
        print('Artist name is empty, cannot load songs');
        return;
      }

      // Query the songs table for matching artist name, case-insensitive
      final List<dynamic> response = await Supabase.instance.client
          .from('songs')
          .select()
          .ilike('artist', artistName)
          .eq('isTop', true)
          .order('created_at')
          .limit(10);
      
      print('Supabase response: $response'); // Debug print
      
      // Convert each item in the response to Map<String, dynamic>
      final convertedSongs = response.map((song) {
        // Ensure all required fields are present and of correct type
        return {
          'id': song['id']?.toString() ?? '',
          'title': song['title']?.toString() ?? 'Unknown Title',
          'artist': song['artist']?.toString() ?? artistName,
          'image_url': song['image_url']?.toString() ?? '',
          'audio_url': song['audio_url']?.toString() ?? '',
          'duration': song['duration']?.toString() ?? '0',
          'isTop': song['isTop'] == true,
        };
      }).toList();

      print('Converted songs: $convertedSongs'); // Debug print

      setState(() {
        topSongs = List<Map<String, dynamic>>.from(convertedSongs);
      });

      print('Successfully loaded ${topSongs.length} top songs');
      if (topSongs.isNotEmpty) {
        print('First song details: ${topSongs.first}');
      }
      
    } catch (e, stackTrace) {
      print('Error loading top songs: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        topSongs = []; // Set empty list on error
      });
    }
  }

  Future<void> loadAlbums() async {
    try {
      final String artistName = widget.artist['artist']?.toString() ?? '';
      
      if (artistName.isEmpty) {
        print('Artist name is empty, cannot load albums');
        return;
      }

      final List<dynamic> response = await Supabase.instance.client
          .from('albums')
          .select()
          .ilike('artist', artistName)
          .order('release_date', ascending: false);
      
      setState(() {
        albums = response.map((album) => {
          'title': album['title']?.toString() ?? 'Unknown Album',
          'image_url': album['image_url']?.toString() ?? '',
          'release_date': album['release_date']?.toString() ?? '',
        }).toList();
      });
      
    } catch (e) {
      print('Error loading albums: $e');
      setState(() {
        albums = [];
      });
    }
  }

  Future<void> loadArtistData() async {
    try {
      // Use the artist name from the recommended_artists table
      final artistName = widget.artist['artist']; // This is the field name in recommended_artists
      print('Looking up artist details for: $artistName'); // Debug log
      
      final response = await widget.musicService.getArtistPage(artistName);
      print('Found artist page data: $response'); // Debug log
      
      // Ensure artist_details length check is done safely
      final artistDetails = response['artist_details'] as String?;
      final hasDetails = artistDetails != null && artistDetails.isNotEmpty;
      
      setState(() {
        artistData = {
          ...response,
          'artist_details_length': hasDetails ? artistDetails!.length : 0,
        };
      });
    } catch (e) {
      print('Error loading artist data: $e');
    }
  }

  void _showFullDetails() {
    setState(() {
      showFullDetails = true;
    });
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: Stack(
            children: [
              CustomPaint(
                painter: BlobPainter(),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
              ),
              Column(
                children: [
                  // Fixed AppBar
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          'assets/icons/back_button.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      artistData?['artist_name'] ?? 'Loading...',
                      style: GoogleFonts.raleway(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.getPrimaryTextColor(),
                      ),
                    ),
                    centerTitle: true,
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Artist header section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Artist Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: artistData?['artist_image_url'] != null
                                      ? SizedBox(
                                          width: 130,
                                          height: 160,
                                          child: Image.network(
                                            artistData!['artist_image_url'],
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          width: 130,
                                          height: 160,
                                          color: Colors.grey[800],
                                        ),
                                ),
                                SizedBox(width: 16),
                                // Artist Details
                                Expanded(
                                  child: Container(
                                    height: 160,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            artistData?['artist_details'] ?? '',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                            maxLines: 6,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if ((artistData?['artist_details'] ?? '').isNotEmpty)
                                            TextButton(
                                              onPressed: _showFullDetails,
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(50, 20),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Read More',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rest of your existing content sections (Latest Release, Top Songs, Albums)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            child: Text(
                              'Latest Release',
                              style: GoogleFonts.raleway(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.getPrimaryTextColor(),
                              ),
                            ),
                          ),
                          if (artistData != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Album Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: artistData?['latest_release_album_image_url'] != null
                                      ? Image.network(
                                          artistData!['latest_release_album_image_url'],
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[800],
                                        ),
                                  ),
                                  SizedBox(width: 16),
                                  // Release Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artistData?['latest_release'] ?? 'Release date unavailable',
                                          style: GoogleFonts.lato(
                                            color: Colors.white70,
                                            fontSize: 12, // Reduced from 14
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          artistData?['latest_release_album_url'] ?? 'Album name unavailable',
                                          style: GoogleFonts.lato(
                                            color: themeProvider.getPrimaryTextColor(),
                                            fontSize: 18, // Increased from 16
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${artistData?['latest_release_number_of_songs'] ?? 0} songs',
                                          style: GoogleFonts.lato(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4), // Changed bottom padding from 8 to 4
                            child: Text(
                              'Top Songs',
                              style: GoogleFonts.raleway(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.getPrimaryTextColor(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: topSongs.length,
                                itemBuilder: (context, index) {
                                  final song = topSongs[index];
                                  final isPlaying = widget.currentSong != null &&
                                      widget.currentSong!['title'] == song['title'];

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        song['image_url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song['title'],
                                          style: TextStyle(
                                            color: themeProvider.getPrimaryTextColor(),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis, // Add this line
                                          maxLines: 1, // Add this line
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          song['artist'],
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis, // Add this line
                                          maxLines: 1, // Add this line
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        widget.currentSong != null && 
                                        widget.currentSong!['id'] == song['id'] ? 
                                        Icons.pause : Icons.play_arrow,
                                        color: themeProvider.getPrimaryTextColor(),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final audioUrl = song['audio_url'];
                                          if (audioUrl == null || audioUrl.isEmpty) {
                                            throw Exception('Song URL is missing');
                                          }
                                
                                          final songData = {
                                            ...song,
                                            'id': song['id'],
                                            'image_url': song['image_url'],
                                            'title': song['title'] ?? 'Unknown Title',
                                            'artist': song['artist'] ?? 'Unknown Artist',
                                            'audio_url': audioUrl,
                                          };
                                
                                          // Update parent state BEFORE playing the song
                                          widget.onSongPlay(songData);
                                          setState(() {}); // Force a rebuild of the UI
                                
                                          // Get the index of the current song
                                          final currentIndex = topSongs.indexWhere((s) => s['id'] == song['id']);
                                          
                                          // Get subsequent songs
                                          final subsequentSongs = topSongs
                                              .skip(currentIndex + 1)
                                              .map((s) => {
                                                    ...s,
                                                    'image_url': s['image_url'],
                                                  })
                                              .toList();
                                
                                          // Play the song with subsequent songs in queue
                                          await widget.musicService.playSong(
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
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Albums',
                              style: GoogleFonts.raleway(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.getPrimaryTextColor(),
                              ),
                            ),
                          ),
                          // Replace the Albums grid comment with this:
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7, // Adjusted to give more space for text
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                final album = albums[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[900],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5, // More space for image
                                        child: Image.network(
                                          album['image_url'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2, // Space for text content
                                        child: Container(
                                          color: Colors.black.withOpacity(0.9),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start, // Add this line
                                            children: [
                                              Text(
                                                album['title'],
                                                style: TextStyle(
                                                  color: themeProvider.getPrimaryTextColor(),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.left, // Changed from center
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                album['release_date'],
                                                style: TextStyle(
                                                  color: Colors.grey[700], // Made brighter
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.5,
                                                ),
                                                textAlign: TextAlign.left, // Changed from center
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 100), // Space for bottom player
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              buildFloatingBottomPlayer(
                currentSong: widget.currentSong,
                musicService: widget.musicService,
                onSongPlay: widget.onSongPlay,
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
                  selectedItemColor: themeProvider.getPrimaryTextColor(),
                  unselectedItemColor: Colors.grey.withOpacity(0.6),
                  currentIndex: widget.selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  onTap: widget.onIndexChanged,
                  items: [
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/icons/home_icon.svg',
                        colorFilter: ColorFilter.mode(
                          widget.selectedIndex == 0 ? themeProvider.getPrimaryTextColor() : Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/icons/search_icon.svg',
                        colorFilter: ColorFilter.mode(
                          widget.selectedIndex == 1 ? themeProvider.getPrimaryTextColor() : Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/icons/library_icon.svg',
                        colorFilter: ColorFilter.mode(
                          widget.selectedIndex == 2 ? themeProvider.getPrimaryTextColor() : Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Library',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Full Details Overlay
        if (showFullDetails)
          GestureDetector(
            onTap: () => setState(() => showFullDetails = false),
            child: Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(32),
                  padding: EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'About ${artistData?['artist_name']}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.getPrimaryTextColor(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            artistData?['artist_details'] ?? '',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => showFullDetails = false),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
