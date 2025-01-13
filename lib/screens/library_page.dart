import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; // Add this import
import 'package:image_cropper/image_cropper.dart'; // Add this import
import 'package:resonance/models/playlist.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LibraryPage extends StatefulWidget {
  final Function(int) onNavigate;
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const LibraryPage({
    Key? key, 
    required this.onNavigate,
    required this.selectedIndex,        
    required this.onIndexChanged,       
  }) : super(key: key);

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isGridView = true;
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final data = await supabase
          .from('playlist')
          .select()
          .eq('user_id', userId)  // Add this filter
          .order('created_at', ascending: false);

      setState(() {
        _playlists = data.map((json) => Playlist.fromJson(json)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlists: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Library',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: themeProvider.getPrimaryTextColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isGridView ? _buildGridView() : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlaylistScreen()),
          );
          _loadPlaylists(); // Reload playlists after returning from create screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlists.isEmpty) {
      return const Center(child: Text('No playlists yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return Card(
            color: Colors.transparent, // Add this
            elevation: 0, // Add this
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to playlist details
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  playlist.imageUrl != null
                      ? Image.network(
                          playlist.imageUrl!,
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.4),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note, size: 50),
                        ),
                  Positioned(
                    left: 3,
                    bottom: 8,
                    child: Text(
                      playlist.playlistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlists.isEmpty) {
      return const Center(child: Text('No playlists yet'));
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      child: ListView.builder(
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return ListTile(
            leading: playlist.imageUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(playlist.imageUrl!))
                : const CircleAvatar(child: Icon(Icons.music_note)),
            title: Text(playlist.playlistName),
            subtitle: const Text('0 songs'), // TODO: Add song count
            onTap: () {
              // TODO: Navigate to playlist details
            },
          );
        },
      ),
    );
  }

  void showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement playlist creation logic
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({Key? key}) : super(key: key);

  @override
  _CreatePlaylistScreenState createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    
    print('Checking auth state:');
    print('Session: ${session?.toJson()}');
    print('User: ${supabase.auth.currentUser?.toJson()}');
    print('Session User ID: ${session?.user.id}');

    if (session?.user == null) {
      print('No active session found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      setState(() {
        _image = croppedFile != null ? File(croppedFile.path) : null;
      });
    }
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      print('Current auth state:');
      print('Session: ${session?.toJson()}');
      print('Access Token: ${session?.accessToken}');
      
      if (session?.user == null) {
        print('No active session found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to create a playlist')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = session!.user.id;
      
      // First ensure user exists in public.users table
      try {
        final userExists = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();
            
        if (userExists == null) {
          // Create user record if it doesn't exist
          await supabase
              .from('users')
              .insert({
                'id': userId,
                'display_name': session.user.userMetadata?['display_name'] ?? '',
                'photo_url': session.user.userMetadata?['photo_url'] ?? '',
                'firebase_uid': session.user.userMetadata?['firebase_uid'] ?? '',
              });
          print('Created user record in public.users table');
        }
      } catch (e) {
        print('Error checking/creating user: $e');
        // Create user record if select failed
        await supabase
            .from('users')
            .upsert({
              'id': userId,
              'display_name': session.user.userMetadata?['display_name'] ?? '',
              'photo_url': session.user.userMetadata?['photo_url'] ?? '',
              'firebase_uid': session.user.userMetadata?['firebase_uid'] ?? '',
            });
        print('Upserted user record in public.users table');
      }

      // Continue with existing image upload code...
      String? imageUrl;
      if (_image != null) {
        print('Uploading image...');
        try {
          final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${_image!.path.split('/').last}';
          final bytes = await _image!.readAsBytes();
          
          print('Uploading to path: $fileName');
          final storageResponse = await supabase.storage
              .from('playlist_covers')
              .uploadBinary(
                fileName, // Removed 'public/' prefix
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          print('Storage response: $storageResponse');
          
          // Get the public URL
          imageUrl = supabase.storage
              .from('playlist_covers')
              .getPublicUrl(fileName); // Removed 'public/' prefix
          print('Image URL: $imageUrl');

        } catch (e, stackTrace) {
          print('Storage error details:');
          print('Error: $e');
          print('Stack trace: $stackTrace');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Storage error: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      print('Inserting playlist into database...');
      final response = await supabase
          .from('playlist')
          .insert({
            'playlist_name': _nameController.text,
            'image_url': imageUrl,
            'user_id': userId,
          })
          .select()
          .limit(1)
          .single();

      print('Database response: $response');

      if (response != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist created successfully!')),
        );
      } else {
        print('Error creating playlist: No response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating playlist')),
        );
      }
    } catch (e) {
      print('Error creating playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
              ),
            ),
            const SizedBox(height: 16),
            _image == null
                ? const Text('No image selected.')
                : Image.file(_image!),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPlaylist,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
