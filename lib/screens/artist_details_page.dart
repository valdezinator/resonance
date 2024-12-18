// import 'package:flutter/material.dart';
// import '../services/music_service.dart';
// import '../widgets/bottom_player.dart';
// import '../widgets/floating_player_mixin.dart';

// class ArtistDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> artist;
//   final MusicService musicService;
//   final Function(Map<String, dynamic>?) onSongPlay;
//   final Map<String, dynamic>? currentSong;

//   const ArtistDetailsPage({
//     Key? key,
//     required this.artist,
//     required this.musicService,
//     required this.onSongPlay,
//     this.currentSong,
//   }) : super(key: key);

//   @override
//   State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
// }

// class _ArtistDetailsPageState extends State<ArtistDetailsPage> with FloatingPlayerMixin {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 expandedHeight: 300,
//                 pinned: true,
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Stack(
//                     fit: StackFit.expand,
//                     children: [
//                       Image.network(
//                         widget.artist['image_url'],
//                         fit: BoxFit.cover,
//                       ),
//                       Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               Colors.transparent,
//                               Colors.black.withOpacity(0.7),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   title: Text(
//                     widget.artist['artist'],
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Popular Songs',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       FutureBuilder<List<Map<String, dynamic>>>(
//                         future: widget.musicService.getArtistSongs(widget.artist['id']),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState == ConnectionState.waiting) {
//                             return Center(child: CircularProgressIndicator());
//                           }

//                           if (snapshot.hasError) {
//                             return Text(
//                               'Error loading songs: ${snapshot.error}',
//                               style: TextStyle(color: Colors.red),
//                             );
//                           }

//                           final songs = snapshot.data ?? [];
//                           return ListView.builder(
//                             shrinkWrap: true,
//                             physics: NeverScrollableScrollPhysics(),
//                             itemCount: songs.length,
//                             itemBuilder: (context, index) {
//                               final song = songs[index];
//                               return ListTile(
//                                 leading: ClipRRect(
//                                   borderRadius: BorderRadius.circular(4),
//                                   child: Image.network(
//                                     song['image_url'],
//                                     width: 48,
//                                     height: 48,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                                 title: Text(
//                                   song['title'],
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                                 subtitle: Text(
//                                   '${song['plays']} plays',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                                 trailing: IconButton(
//                                   icon: Icon(Icons.play_circle_filled,
//                                     color: Colors.white),
//                                   onPressed: () async {
//                                     try {
//                                       widget.onSongPlay(song);
//                                       await widget.musicService
//                                           .playSong(song['audio_url']);
//                                     } catch (e) {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(
//                                           content: Text('Failed to play song: $e'),
//                                           backgroundColor: Colors.red,
//                                         ),
//                                       );
//                                     }
//                                   },
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           buildFloatingBottomPlayer(
//             currentSong: widget.currentSong,
//             musicService: widget.musicService,
//             onSongPlay: widget.onSongPlay,
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import '../services/music_service.dart';
// import '../widgets/bottom_player.dart';
// import '../widgets/floating_player_mixin.dart';

// class ArtistDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> artist;
//   final MusicService musicService;
//   final Function(Map<String, dynamic>?) onSongPlay;
//   final Map<String, dynamic>? currentSong;

//   const ArtistDetailsPage({
//     Key? key,
//     required this.artist,
//     required this.musicService,
//     required this.onSongPlay,
//     this.currentSong,
//   }) : super(key: key);

//   @override
//   State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
// }

// class _ArtistDetailsPageState extends State<ArtistDetailsPage> with FloatingPlayerMixin {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 backgroundColor: Colors.transparent,
//                 expandedHeight: 300,
//                 pinned: true,
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.red.withOpacity(0.6),
//                           Colors.black,
//                         ],
//                       ),
//                     ),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Positioned(
//                           top: 60,
//                           left: 0,
//                           right: 0,
//                           child: Center(
//                             child: Image.network(
//                               widget.artist['image_url'],
//                               height: 200,
//                               width: 200,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 20,
//                           left: 0,
//                           right: 0,
//                           child: Center(
//                             child: Text(
//                               widget.artist['artist'],
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Text(
//                         'Top Hits',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     FutureBuilder<List<Map<String, dynamic>>>(
//                       future: widget.musicService.getArtistSongs(widget.artist['id']),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return Center(child: CircularProgressIndicator());
//                         }

//                         if (snapshot.hasError) {
//                           return Text(
//                             'Error loading songs: ${snapshot.error}',
//                             style: TextStyle(color: Colors.red),
//                           );
//                         }

//                         final songs = snapshot.data ?? [];
//                         return ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: songs.length,
//                           itemBuilder: (context, index) {
//                             final song = songs[index];
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16.0,
//                                 vertical: 8.0,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Text(
//                                     '${index + 1}',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   SizedBox(width: 16),
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(4),
//                                     child: Image.network(
//                                       song['image_url'],
//                                       width: 48,
//                                       height: 48,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                   SizedBox(width: 16),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           song['title'],
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         Text(
//                                           '3:24',
//                                           style: TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: Icon(
//                                       Icons.more_vert,
//                                       color: Colors.white,
//                                     ),
//                                     onPressed: () {},
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Top albums',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 16),
//                           SizedBox(
//                             height: 150,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               itemCount: 5,
//                               itemBuilder: (context, index) {
//                                 return Padding(
//                                   padding: const EdgeInsets.only(right: 16.0),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Container(
//                                       width: 150,
//                                       color: Colors.grey[800],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           buildFloatingBottomPlayer(
//             currentSong: widget.currentSong,
//             musicService: widget.musicService,
//             onSongPlay: widget.onSongPlay,
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import '../services/music_service.dart';
// import '../widgets/bottom_player.dart';
// import '../widgets/floating_player_mixin.dart';

// class ArtistDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> artist;
//   final MusicService musicService;
//   final Function(Map<String, dynamic>?) onSongPlay;
//   final Map<String, dynamic>? currentSong;

//   const ArtistDetailsPage({
//     Key? key,
//     required this.artist,
//     required this.musicService,
//     required this.onSongPlay,
//     this.currentSong,
//   }) : super(key: key);

//   @override
//   State<ArtistDetailsPage> createState() => _ArtistDetailsPageState();
// }

// class _ArtistDetailsPageState extends State<ArtistDetailsPage> with FloatingPlayerMixin {
//   String formatDuration(int seconds) {
//     final duration = Duration(seconds: seconds);
//     final minutes = duration.inMinutes;
//     final remainingSeconds = duration.inSeconds.remainder(60);
//     return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 backgroundColor: Colors.transparent,
//                 expandedHeight: 300,
//                 pinned: true,
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.red.withOpacity(0.6),
//                           Colors.black,
//                         ],
//                       ),
//                     ),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Positioned(
//                           top: 60,
//                           left: 0,
//                           right: 0,
//                           child: Center(
//                             child: Image.network(
//                               widget.artist['image_url'],
//                               height: 200,
//                               width: 200,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 20,
//                           left: 0,
//                           right: 0,
//                           child: Center(
//                             child: Text(
//                               widget.artist['artist'],
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SliverToBoxAdapter(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Text(
//                         'Top Hits',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     FutureBuilder<List<Map<String, dynamic>>>(
//                       future: widget.musicService.getArtistTopHits(widget.artist['id']),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return Center(child: CircularProgressIndicator());
//                         }

//                         if (snapshot.hasError) {
//                           return Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Text(
//                               'Error loading songs: ${snapshot.error}',
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           );
//                         }

//                         final songs = snapshot.data ?? [];
//                         return ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: songs.length,
//                           itemBuilder: (context, index) {
//                             final song = songs[index];
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16.0,
//                                 vertical: 8.0,
//                               ),
//                               child: InkWell(
//                                 onTap: () async {
//                                   try {
//                                     widget.onSongPlay(song);
//                                     await widget.musicService.playSong(
//                                       song['audio_url'],
//                                       currentSong: song,
//                                     );
//                                     await widget.musicService.incrementTopHitPlayCount(
//                                       song['id'],
//                                       widget.artist['id'],
//                                     );
//                                   } catch (e) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text('Failed to play song: $e'),
//                                         backgroundColor: Colors.red,
//                                       ),
//                                     );
//                                   }
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       '${song['rank']}',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                     SizedBox(width: 16),
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(4),
//                                       child: Image.network(
//                                         song['image_url'],
//                                         width: 48,
//                                         height: 48,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                     SizedBox(width: 16),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             song['title'],
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                           Text(
//                                             formatDuration(song['duration'] ?? 0),
//                                             style: TextStyle(
//                                               color: Colors.grey,
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     Text(
//                                       '${song['play_count']} plays',
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                     IconButton(
//                                       icon: Icon(
//                                         Icons.more_vert,
//                                         color: Colors.white,
//                                       ),
//                                       onPressed: () {
//                                         // Show options menu
//                                         showModalBottomSheet(
//                                           context: context,
//                                           backgroundColor: Colors.grey[900],
//                                           builder: (context) => Column(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               ListTile(
//                                                 leading: Icon(Icons.playlist_add, color: Colors.white),
//                                                 title: Text('Add to playlist', style: TextStyle(color: Colors.white)),
//                                                 onTap: () {
//                                                   // Add to playlist functionality
//                                                   Navigator.pop(context);
//                                                 },
//                                               ),
//                                               ListTile(
//                                                 leading: Icon(Icons.favorite_border, color: Colors.white),
//                                                 title: Text('Like', style: TextStyle(color: Colors.white)),
//                                                 onTap: () async {
//                                                   await widget.musicService.likeSong(song['id']);
//                                                   Navigator.pop(context);
//                                                 },
//                                               ),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Top albums',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 16),
//                           SizedBox(
//                             height: 150,
//                             child: ListView.builder(
//                               scrollDirection: Axis.horizontal,
//                               itemCount: 5,
//                               itemBuilder: (context, index) {
//                                 return Padding(
//                                   padding: const EdgeInsets.only(right: 16.0),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Container(
//                                       width: 150,
//                                       color: Colors.grey[800],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           buildFloatingBottomPlayer(
//             currentSong: widget.currentSong,
//             musicService: widget.musicService,
//             onSongPlay: widget.onSongPlay,
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';

class ArtistDetailsPage extends StatefulWidget {
  final Map<String, dynamic> artist;
  final MusicService musicService;
  final Function(Map<String, dynamic>?) onSongPlay;
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

class _ArtistDetailsPageState extends State<ArtistDetailsPage>
    with FloatingPlayerMixin {
  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.red.withOpacity(0.6),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: widget.artist['image_url'] != null
                                ? Image.network(
                                    widget.artist['image_url'],
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.person,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              widget.artist['artist'] ?? 'Unknown Artist',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Top Hits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: widget.musicService
                          .getArtistTopHits(widget.artist['id']),
                      builder: (context, snapshot) {
                        print(
                            'FutureBuilder state: ${snapshot.connectionState}');
                        print('FutureBuilder error: ${snapshot.error}');
                        print('FutureBuilder data: ${snapshot.data}');

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading songs: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final songs = snapshot.data ?? [];
                        if (songs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No songs found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    widget.onSongPlay(song);
                                    await widget.musicService.playSong(
                                      song['audio_url'] ?? '',
                                      currentSong: song,
                                    );
                                    await widget.musicService
                                        .incrementTopHitPlayCount(
                                      song['id'],
                                      widget.artist['id'],
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to play song: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: song['image_url'] != null
                                          ? Image.network(
                                              song['image_url'],
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.grey[800],
                                              child: Icon(
                                                Icons.music_note,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song['title'] ?? 'Unknown Title',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            song['duration'] ?? '0:00',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${song['play_count'] ?? 0} plays',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.grey[900],
                                          builder: (context) => Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: Icon(
                                                    Icons.playlist_add,
                                                    color: Colors.white),
                                                title: Text('Add to playlist',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(
                                                    Icons.favorite_border,
                                                    color: Colors.white),
                                                title: Text('Like',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                onTap: () async {
                                                  await widget.musicService
                                                      .likeSong(song['id']);
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top albums',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 150,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
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
    );
  }
}
