import 'package:flutter/material.dart';
import '../services/music_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic>? currentSong;
  final Function(Map<String, dynamic>?) onSongPlay;
  final MusicService musicService;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const SearchPage({
    Key? key,
    this.currentSong,
    required this.onSongPlay,
    required this.musicService,
    required this.selectedIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with FloatingPlayerMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isPlayerVisible = false;

  // Browse categories with color gradients
  final List<Map<String, dynamic>> _browseCategories = [
    {
      'title': 'Podcasts',
      'color1': const Color(0xFF8C67AC),
      'color2': const Color(0xFF9B59B6),
    },
    {
      'title': 'Live Events',
      'color1': const Color(0xFFE67E22),
      'color2': const Color(0xFFD35400),
    },
    {
      'title': 'Made For You',
      'color1': const Color(0xFF1DB954),
      'color2': const Color(0xFF1ED760),
    },
    {
      'title': 'New Releases',
      'color1': const Color(0xFFE91E63),
      'color2': const Color(0xFFC2185B),
    },
    {
      'title': 'Hindi',
      'color1': const Color(0xFF3498DB),
      'color2': const Color(0xFF2980B9),
    },
    {
      'title': 'Punjabi',
      'color1': const Color(0xFFE74C3C),
      'color2': const Color(0xFFC0392B),
    },
  ];

  // Top genres with updated structure
  final List<Map<String, dynamic>> _topGenres = [
    {
      'title': 'Pop',
      'image_url': 'https://i.scdn.co/image/ab67706f00000003e8e28219724c2423afa4d320',
      'description': 'Popular hits you\'ll love',
    },
    {
      'title': 'Hip-Hop',
      'image_url': 'https://i.scdn.co/image/ab67706f00000003e8e28219724c2423afa4d320',
      'description': 'Latest hip-hop tracks',
    },
  ];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.musicService.searchSongs(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: themeProvider.getPrimaryTextColor()),
        decoration: InputDecoration(
          hintText: 'What do you want to listen to?',
          hintStyle: TextStyle(color: themeProvider.getSecondaryTextColor()),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: Icon(Icons.mic, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildBrowseCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 24, bottom: 16),
          child: Text(
            'Browse all',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _browseCategories.length,
          itemBuilder: (context, index) {
            final category = _browseCategories[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    category['color1'],
                    category['color2'],
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Text(
                      category['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopGenres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 24, bottom: 16),
          child: Text(
            'Your top genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _topGenres.length,
            itemBuilder: (context, index) {
              final genre = _topGenres[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        genre['image_url'],
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160,
                          width: 160,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      genre['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      genre['description'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return ListTile(
          leading: Hero(
            tag: 'song-image-${song['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                song['image_url'] ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          title: Text(
            song['title'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(
            song['artist'] ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              // Show options menu
            },
          ),
          onTap: () async {
            try {
              final audioUrl = song['audio_url'];
              if (audioUrl == null || audioUrl.isEmpty) {
                throw Exception('Song URL is missing');
              }

              final standardizedSong = {
                ...song,
                'url': audioUrl,
                'title': song['title'] ?? 'Unknown Title',
                'artist': song['artist'] ?? 'Unknown Artist',
                'image_url': song['image_url'] ?? '',
                'id': song['id']?.toString() ?? '',
                'duration': song['duration']?.toString() ?? '0',
              };

              widget.onSongPlay(standardizedSong);

              final nextSongIndex = index + 1;
              final subsequentSongs = nextSongIndex < _searchResults.length
                  ? [_searchResults[nextSongIndex]]
                  : null;

              await widget.musicService.playSong(
                audioUrl,
                currentSong: standardizedSong,
                subsequentSongs: subsequentSongs,  // Use subsequentSongs instead of nextSong
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to play song: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Container(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: _searchController.text.isEmpty
                        ? SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + 80,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBrowseCategories(),
                                _buildTopGenres(),
                              ],
                            ),
                          )
                        : _buildSearchResults(),
                  ),
                ],
              ),
            ),
            if (_isPlayerVisible)
              buildFloatingBottomPlayer(
                currentSong: widget.currentSong,
                musicService: widget.musicService,
                onSongPlay: widget.onSongPlay,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
