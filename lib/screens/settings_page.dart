import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';
import '../widgets/floating_player_mixin.dart';

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
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white, // This sets the text color to white
          ),
        ),
        // backgroundColor: Color(0xFF2C2F33), // Dark background
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue[900],
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : null,
                  child: currentUser?.photoURL == null
                      ? Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 16),
                Text(
                  currentUser?.displayName ?? 'User',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          _buildSectionHeader('Account'),
          _buildListTile(
            title: 'User Profile',
            icon: 'assets/icons/user.svg',
            onTap: () {
              // Navigate to user profile
            },
          ),
          _buildListTile(
            title: 'Privacy & Safety',
            icon: 'assets/icons/privacy.svg',
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          _buildSectionHeader('App Settings'),
          _buildSwitchTile(
            title: 'Push Notifications',
            icon: 'assets/icons/notifications.svg',
            value: true, // Example value, replace with actual state
            onChanged: (bool value) {
              // Handle toggle
            },
          ),
          _buildSwitchTile(
            title: 'Dark Mode',
            icon: 'assets/icons/moon.svg',
            value: false, // Example value, replace with actual state
            onChanged: (bool value) {
              // Handle toggle
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => _handleSignOut(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildListTile(
      {required String title,
      required String icon,
      required VoidCallback onTap}) {
    return ListTile(
      leading: SvgPicture.asset(icon, width: 24, height: 24),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
      {required String title,
      required String icon,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: SvgPicture.asset(icon, width: 24, height: 24),
      title: Text(title, style: TextStyle(color: Colors.white)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
}
