import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';
import '../widgets/floating_player_mixin.dart';
import 'privacy_settings_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? currentSong;
  final Function(Map<String, dynamic>?) onSongPlay;
  final MusicService musicService;
  final int selectedIndex;              // Add this
  final Function(int) onIndexChanged;   // Add this

  const SettingsPage({
    Key? key,
    this.currentSong,
    required this.onSongPlay,
    required this.musicService,
    required this.selectedIndex,        // Add this
    required this.onIndexChanged,       // Add this
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with FloatingPlayerMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Add settings state
  final ValueNotifier<bool> _pushNotifications = ValueNotifier(true);
  final ValueNotifier<bool> _darkMode = ValueNotifier(true);
  final ValueNotifier<bool> _highQualityStreaming = ValueNotifier(false);
  final ValueNotifier<bool> _autoPlay = ValueNotifier(true);
  final ValueNotifier<bool> _downloadOverWifiOnly = ValueNotifier(true);

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Sign out from Supabase
      await supabase.Supabase.instance.client.auth.signOut();
      
      // Sign out from Google
      await GoogleSignIn().signOut();
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Navigate to SignInPage and remove all previous routes
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
    return Scaffold(
      backgroundColor: const Color(0xFF0c0f14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Enhanced Profile Section
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white12,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : null,
                  child: currentUser?.photoURL == null
                      ? Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    // TODO: Implement edit profile
                  },
                ),
              ],
            ),
          ),

          _buildSectionHeader('Playback'),
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

          _buildSectionHeader('Downloads'),
          _buildValueListenableBuilder(
            _downloadOverWifiOnly,
            'Download over Wi-Fi only',
            'Save mobile data',
            'assets/icons/wifi.svg',
          ),

          _buildSectionHeader('Notifications'),
          _buildValueListenableBuilder(
            _pushNotifications,
            'Push Notifications',
            'Stay updated with latest releases',
            'assets/icons/notifications.svg',
          ),

          _buildSectionHeader('Appearance'),
          _buildValueListenableBuilder(
            _darkMode,
            'Dark Mode',
            'Toggle dark/light theme',
            'assets/icons/moon.svg',
          ),

          _buildSectionHeader('Account'),
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

          // Enhanced Logout Button
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
          SizedBox(height: 100), // Bottom padding for player
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
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
    );
  }

  Widget _buildValueListenableBuilder(
    ValueNotifier<bool> notifier,
    String title,
    String subtitle,
    String iconPath,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return ListTile(
          leading: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.white70,
              BlendMode.srcIn,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.white60, fontSize: 12),
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
}
