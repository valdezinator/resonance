import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';
import '../widgets/floating_player_mixin.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? currentSong;
  final Function(Map<String, dynamic>) onSongPlay;
  final MusicService musicService;

  const SettingsPage({
    Key? key,
    this.currentSong,
    required this.onSongPlay,
    required this.musicService,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with FloatingPlayerMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 26, 32, 43),
                child: Column(
                  children: [
                    // Profile Header
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue[900],
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peter Parker',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Free Plan',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    Divider(color: Colors.grey[800]),
                    
                    // Settings List
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.account_circle_outlined,
                            title: 'Account',
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            icon: Icons.lock_outline,
                            title: 'Privacy',
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            icon: Icons.storage_outlined,
                            title: 'Data Usage',
                            onTap: () {},
                          ),
                          Divider(color: Colors.grey[800]),
                          _buildSettingsTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Log Out',
                            onTap: () {},
                            textColor: Colors.red,
                          ),
                        ],
                      ),
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
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
} 