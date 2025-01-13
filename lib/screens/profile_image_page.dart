import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/music_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'privacy_settings_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileImagePage extends StatefulWidget {
  final MusicService musicService;

  const ProfileImagePage({Key? key, required this.musicService}) : super(key: key);

  @override
  _ProfileImagePageState createState() => _ProfileImagePageState();
}

class _ProfileImagePageState extends State<ProfileImagePage> {
  String? _imageUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _showListeningActivity = true;

  // Add settings state
  final ValueNotifier<bool> _pushNotifications = ValueNotifier(true);
  final ValueNotifier<bool> _darkMode = ValueNotifier(true);
  final ValueNotifier<bool> _highQualityStreaming = ValueNotifier(false);
  final ValueNotifier<bool> _autoPlay = ValueNotifier(true);
  final ValueNotifier<bool> _downloadOverWifiOnly = ValueNotifier(true);
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadPrivacySettings();
    _loadThemePreference();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imageUrl = prefs.getString('profile_image');
    });
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showListeningActivity = prefs.getBool('show_listening_activity') ?? true;
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode.value = prefs.getBool('dark_mode') ?? true;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      // Here you would typically upload the image to your server
      // For now, we'll just save the path locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', image.path);
    }
  }

  Widget _buildRecentlyPlayedSection() {
    if (!_showListeningActivity) {
      return const SizedBox.shrink(); // Don't show anything if listening activity is disabled
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Played',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await widget.musicService.clearPlayHistory();
                  setState(() {}); // Refresh the UI
                },
                child: Text(
                  'Clear History',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.musicService.getRecentlyPlayed(limit: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading history',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final songs = snapshot.data ?? [];
              if (songs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No songs played yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final songData = songs[index]['songs'];
                  final playedAt = songData['played_at'] as DateTime;
                  final timeAgo = _getTimeAgo(playedAt);

                  return InkWell(
                    onTap: () async {
                      try {
                        await widget.musicService.playSong(
                          songData['audio_url'],
                          currentSong: songData,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to play song: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: songData['image_url'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: Icon(Icons.music_note, color: Colors.white54),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  songData['title'] ?? 'Unknown Title',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  songData['artist'] ?? 'Unknown Artist',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await supabase.Supabase.instance.client.auth.signOut();
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
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
          'Profile',
          style: TextStyle(color: themeProvider.textColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Image Section
            SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : _imageUrl != null
                              ? FileImage(File(_imageUrl!))
                              : null,
                      child: (_imageFile == null && _imageUrl == null)
                          ? Icon(Icons.person, size: 80, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              currentUser?.displayName ?? 'User',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentUser?.email ?? '',
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),

            // Recently Played Section (if enabled)
            _buildRecentlyPlayedSection(),
            
            // Settings Sections
            _buildSettingsSection('Playback', [
              _buildValueListenableBuilder(
                _highQualityStreaming,
                'High Quality Streaming',
                'Stream music in highest quality',
                'assets/icons/quality.svg',
              ),
              _buildValueListenableBuilder(
                _autoPlay,
                'AutoPlay',
                'Automatically play similar songs',
                'assets/icons/autoplay.svg',
              ),
            ]),

            _buildSettingsSection('Downloads', [
              _buildValueListenableBuilder(
                _downloadOverWifiOnly,
                'Download over Wi-Fi only',
                'Save mobile data',
                'assets/icons/wifi.svg',
              ),
            ]),

            _buildSettingsSection('Notifications', [
              _buildValueListenableBuilder(
                _pushNotifications,
                'Push Notifications',
                'Stay updated with latest releases',
                'assets/icons/notifications.svg',
              ),
            ]),

            _buildSettingsSection('Appearance', [
              _buildValueListenableBuilder(
                _darkMode,
                'Dark Mode',
                'Toggle dark/light theme',
                'assets/icons/moon.svg',
              ),
            ]),

            _buildSettingsSection('Account', [
              _buildListTile(
                title: 'Privacy & Security',
                subtitle: 'Manage your account security',
                icon: 'assets/icons/privacy.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsPage(),
                    ),
                  );
                },
              ),
            ]),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => _handleSignOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildValueListenableBuilder(
    ValueNotifier<bool> notifier,
    String title,
    String subtitle,
    String iconPath,
  ) {
    if (title == 'Dark Mode') {
      return ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, value, child) {
          return ListTile(
            leading: SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Provider.of<ThemeProvider>(context).textColor,
                BlendMode.srcIn,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context).textColor,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: Provider.of<ThemeProvider>(context).secondaryTextColor,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: value,
              onChanged: (newValue) async {
                notifier.value = newValue;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('dark_mode', newValue);
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              activeColor: Colors.blue,
            ),
          );
        },
      );
    }

    // Default case for other settings
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return ListTile(
          leading: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Provider.of<ThemeProvider>(context).textColor,
              BlendMode.srcIn,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).textColor,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).secondaryTextColor,
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: (newValue) => notifier.value = newValue,
            activeColor: Colors.blue,
          ),
        );
      },
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(Colors.white70, BlendMode.srcIn),
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
