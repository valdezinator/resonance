import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';

class ArtistDetailsPage extends StatefulWidget {
  final Map<String, dynamic> artist;
  final MusicService musicService;
  final Function(Map<String, dynamic>) onSongPlay;
  final Map<String, dynamic>? currentSong;

  const ArtistDetailsPage({
    Key? key,
    required this.artist,
    required this.musicService,
    required this.onSongPlay,
    this.currentSong,
  }) : super(key: key);

  @override
  State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
}

class _ArtistDetailsPageState extends State<ArtistDetailsPage> with FloatingPlayerMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.artist['image_url'],
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    widget.artist['artist'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popular Songs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: widget.musicService.getArtistSongs(widget.artist['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Text(
                              'Error loading songs: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          final songs = snapshot.data ?? [];
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    song['image_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  song['title'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${song['plays']} plays',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.play_circle_filled, 
                                    color: Colors.white),
                                  onPressed: () async {
                                    try {
                                      widget.onSongPlay(song);
                                      await widget.musicService
                                          .playSong(song['audio_url']);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to play song: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
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
    );
  }
} 