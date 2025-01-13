import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';
import 'dart:math' as math;

class BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    
    // Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0c0f14),
    );

    void drawBlob(Offset center, double radius, Color color, double opacity) {
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
      
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, 0.0),
          radius: 1.0,
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2));
      
      canvas.drawPath(path, paint);
    }

    // Draw multiple blobs with different sizes and positions
    final blobConfigs = [
      // Top section blobs
      {'x': 0.2, 'y': 0.1, 'radius': 150.0, 'color': const Color(0xFF945e5c), 'opacity': 0.5},
      {'x': 0.8, 'y': 0.15, 'radius': 180.0, 'color': const Color(0xFF145362), 'opacity': 0.4},
      {'x': 0.5, 'y': 0.2, 'radius': 200.0, 'color': const Color(0xFF20202a), 'opacity': 0.3},
      
      // Middle section blobs
      {'x': 0.3, 'y': 0.4, 'radius': 160.0, 'color': const Color(0xFF945e5c), 'opacity': 0.2},
      {'x': 0.7, 'y': 0.45, 'radius': 140.0, 'color': const Color(0xFF145362), 'opacity': 0.3},
      {'x': 0.1, 'y': 0.5, 'radius': 170.0, 'color': const Color(0xFF20202a), 'opacity': 0.2},
      
      // Bottom section blobs
      {'x': 0.8, 'y': 0.7, 'radius': 190.0, 'color': const Color(0xFF945e5c), 'opacity': 0.15},
      {'x': 0.4, 'y': 0.8, 'radius': 150.0, 'color': const Color(0xFF145362), 'opacity': 0.2},
      {'x': 0.6, 'y': 0.9, 'radius': 180.0, 'color': const Color(0xFF20202a), 'opacity': 0.1},
    ];

    for (final config in blobConfigs) {
      drawBlob(
        Offset(size.width * (config['x'] as double), 
               size.height * (config['y'] as double)),
        config['radius'] as double,
        config['color'] as Color,
        config['opacity'] as double,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  @override
  void initState() {
    super.initState();
    print('Artist data from recommended_artists: ${widget.artist}'); // Debug log
    loadArtistData();
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0c0f14),
          body: Stack(
            children: [
              // Replace the gradient Container with CustomPaint
              CustomPaint(
                painter: BlobPainter(),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
              ),
              // Existing CustomScrollView
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    expandedHeight: 250, // Adjusted for perfect balance
                    pinned: true,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset('assets/icons/back_button.svg'),
                      ),
                    ),
                    title: Text(
                      artistData?['artist_name'] ?? 'Loading...',
                      style: GoogleFonts.raleway(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 110, 20, 20), // Adjusted top padding
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Artist Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: artistData?['artist_image_url'] != null
                                  ? SizedBox(
                                      width: 130, // Perfect width for this height
                                      height: 160, // Standard height for artist image
                                      child: Image.network(
                                        artistData!['artist_image_url'],
                                        fit: BoxFit.cover, // Changed to cover for better image fitting
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
                                height: 160, // Match image height
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
                                        maxLines: 6, // Increased from 4 to 6 to show more text
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
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Latest Release Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          child: Text(
                            'Latest Release',
                            style: GoogleFonts.raleway(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                          color: Colors.white,
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
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Top Songs',
                            style: GoogleFonts.raleway(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Top Songs list will be added here
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Albums',
                            style: GoogleFonts.raleway(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Albums grid will be added here
                        SizedBox(height: 100), // Space for bottom player
                      ],
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
                          color: Colors.white,
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
