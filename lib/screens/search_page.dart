import 'package:flutter/material.dart';
import '../services/music_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/bottom_player.dart';
import '../widgets/floating_player_mixin.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic>? currentSong;
  final Function(Map<String, dynamic>?) onSongPlay;
  final MusicService musicService;

  const SearchPage({
    Key? key,
    this.currentSong,
    required this.onSongPlay,
    required this.musicService,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with FloatingPlayerMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isPlayerVisible = false;
  double _dragStart = 0;

  // Update recent picks data with network images and error handling
  final List<Map<String, dynamic>> _recentPicks = [
    {
      'id': '1',
      'title': 'Hot Hits USA',
      'description': 'The hottest tracks in the United States',
      'image_url':
          'https://i.scdn.co/image/ab67706f00000003e8e28219724c2423afa4d320',
    },
    {
      'id': '2',
      'title': 'Hot Hits USA',
      'description': 'The hottest tracks in the United States',
      'image_url':
          'https://i.scdn.co/image/ab67706f00000003e8e28219724c2423afa4d320',
    },
  ];

  // Update recent searches with network images
  final List<Map<String, dynamic>> _recentSearches = [
    {
      'title': 'Lalkara',
      'subtitle': 'Diljit Dosanjh',
      'image_url':
          'https://i.scdn.co/image/ab67616d0000b273c0e9d94656fcf62d607be8a5'
    },
    {
      'title': 'Ni Kude',
      'subtitle': 'Ammy Virk',
      'image_url':
          'https://i.scdn.co/image/ab67616d0000b273d6e0e68c46db4524f7ba9bed'
    },
    {
      'title': 'Dupatta',
      'subtitle': 'Loot',
      'image_url':
          'https://i.scdn.co/image/ab67616d0000b273a45b5b5f1d78d5e9104c4e74'
    },
    {
      'title': 'Just Friend',
      'subtitle': 'Mr. Dass',
      'image_url':
          'https://i.scdn.co/image/ab67616d0000b273e6f407c7f3a0ec98845e4431'
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search for anything',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildRecentPicks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 12),
          child: Text(
            'Your recent picks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: _recentPicks.length,
            itemBuilder: (context, index) {
              final pick = _recentPicks[index];
              return Container(
                width: 160,
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        pick['image_url'] ?? '',
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 160,
                          width: 160,
                          color: Colors.grey[800],
                          child: Icon(Icons.music_note, color: Colors.white),
                        ),
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

  Widget _buildRecentSearches() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final search = _recentSearches[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              search['image_url'] ?? '',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 40,
                height: 40,
                color: Colors.grey[800],
                child: Icon(Icons.music_note, color: Colors.white, size: 20),
              ),
            ),
          ),
          title: Text(
            search['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            search['subtitle'] ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          trailing: Icon(Icons.close, color: Colors.grey[400], size: 20),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
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
          leading: ClipRRect(
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
                child: Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),
          ),
          title: Text(
            song['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            song['artist'] ?? '',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          onTap: () async {
            try {
              // Debug the song data
              print('Song data: $song');

              // Get the audio URL and verify it exists
              final audioUrl = song['audio_url'];
              if (audioUrl == null || audioUrl.toString().isEmpty) {
                throw Exception('Song URL is missing');
              }

              // Create a standardized song object with default values
              final standardizedSong = {
                ...song,
                'url': audioUrl,
                'title': song['title'] ?? 'Unknown Title',
                'artist': song['artist'] ?? 'Unknown Artist',
                'image_url': song['image_url'] ?? '',
                'id': song['id']?.toString() ?? '',
                'duration': song['duration']?.toString() ?? '0',
              };

              print(
                  'Standardized song data: $standardizedSong'); // Add this debug line

              // Call onSongPlay with the standardized song data
              widget.onSongPlay(standardizedSong);

              // Get next song from search results
              final nextSongIndex = index + 1;
              final nextSong = nextSongIndex < _searchResults.length
                  ? _searchResults[nextSongIndex]
                  : null;

              await widget.musicService.playSong(
                audioUrl,
                currentSong: standardizedSong,
                nextSong: nextSong,
              );
            } catch (e) {
              print('Error playing song: $e');
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
    return Container(
      color: const Color.fromARGB(255, 20, 25, 34),
      child: Stack(
        children: [
          Column(
            children: [
              // Add safe area padding and move search bar to top
              SafeArea(
                child: _buildSearchBar(),
              ),
              Expanded(
                child: _searchController.text.isEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecentPicks(),
                            SizedBox(height: 24),
                            _buildRecentSearches(),
                          ],
                        ),
                      )
                    : _buildSearchResults(),
              ),
            ],
          ),
          if (_isPlayerVisible)
            buildFloatingBottomPlayer(
              currentSong: widget.currentSong,
              musicService: widget.musicService,
              onSongPlay: widget.onSongPlay,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
