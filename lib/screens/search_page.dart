import 'package:flutter/material.dart';
import '../services/music_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final MusicService _musicService = MusicService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text('All'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'all';
                _performSearch(_searchController.text);
              });
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.blue[700],
            labelStyle: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Songs'),
            selected: _selectedFilter == 'songs',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'songs';
                _performSearch(_searchController.text);
              });
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.blue[700],
            labelStyle: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Artists'),
            selected: _selectedFilter == 'artists',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'artists';
                _performSearch(_searchController.text);
              });
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.blue[700],
            labelStyle: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 8),
          FilterChip(
            label: Text('Albums'),
            selected: _selectedFilter == 'albums',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'albums';
                _performSearch(_searchController.text);
              });
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.blue[700],
            labelStyle: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

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
      final results =
          await _musicService.searchSongs(query, filter: _selectedFilter);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 26, 32, 43),
      child: Column(
        children: [
          _buildFilterChips(),
          // Results list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[800],
                              child:
                                  Icon(Icons.music_note, color: Colors.white),
                            ),
                          ),
                        ),
                        title: Text(
                          song['title'] ?? 'Unknown Title',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          song['artist'] ?? 'Unknown Artist',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () async {
                          try {
                            final audioUrl = song['mp3_url'] as String?;
                            if (audioUrl == null || audioUrl.isEmpty) {
                              throw Exception('Song URL is missing');
                            }
                            final nextSongIndex = index + 1;
                            String? nextUrl;
                            if (nextSongIndex < _searchResults.length) {
                              nextUrl = _searchResults[nextSongIndex]['mp3_url'] as String?;
                            }
                            await _musicService.playSong(audioUrl, nextSongUrl: nextUrl);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to play song: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          // Search bar at bottom
          Container(
            margin: EdgeInsets.only(left: 16, right: 16, bottom: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(38, 255, 255, 255),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/icons/search_icon.svg',
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                  ),
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _performSearch,
            ),
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
