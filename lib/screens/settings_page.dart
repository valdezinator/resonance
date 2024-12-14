// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../widgets/bottom_player.dart';
// import '../services/music_service.dart';
// import '../widgets/floating_player_mixin.dart';

// class SettingsPage extends StatefulWidget {
//   final Map<String, dynamic>? currentSong;
//   final Function(Map<String, dynamic>?) onSongPlay;
//   final MusicService musicService;

//   const SettingsPage({
//     Key? key,
//     this.currentSong,
//     required this.onSongPlay,
//     required this.musicService,
//   }) : super(key: key);

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> with FloatingPlayerMixin {
//   final User? currentUser = FirebaseAuth.instance.currentUser;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Column(
//           children: [
//             Expanded(
//               child: Container(
//                 color: const Color.fromARGB(255, 26, 32, 43),
//                 child: Column(
//                   children: [
//                     // Profile Header
//                     Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 40,
//                             backgroundColor: Colors.blue[900],
//                             backgroundImage: currentUser?.photoURL != null
//                               ? NetworkImage(currentUser!.photoURL!)
//                               : null,
//                             child: currentUser?.photoURL == null
//                               ? Icon(Icons.person, size: 40, color: Colors.white)
//                               : null,
//                           ),
//                           SizedBox(width: 20),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   currentUser?.displayName ?? 'Guest User',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 Text(
//                                   currentUser?.email ?? 'No email',
//                                   style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     Divider(color: Colors.grey[800]),

//                     // Settings List
//                     Expanded(
//                       child: ListView(
//                         children: [
//                           _buildSettingsTile(
//                             icon: Icons.account_circle_outlined,
//                             title: 'Account',
//                             onTap: () {},
//                           ),
//                           _buildSettingsTile(
//                             icon: Icons.notifications_outlined,
//                             title: 'Notifications',
//                             onTap: () {},
//                           ),
//                           _buildSettingsTile(
//                             icon: Icons.lock_outline,
//                             title: 'Privacy',
//                             onTap: () {},
//                           ),
//                           _buildSettingsTile(
//                             icon: Icons.storage_outlined,
//                             title: 'Data Usage',
//                             onTap: () {},
//                           ),
//                           Divider(color: Colors.grey[800]),
//                           _buildSettingsTile(
//                             icon: Icons.help_outline,
//                             title: 'Help & Support',
//                             onTap: () {},
//                           ),
//                           _buildSettingsTile(
//                             icon: Icons.logout,
//                             title: 'Log Out',
//                             onTap: () {},
//                             textColor: Colors.red,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         buildFloatingBottomPlayer(
//           currentSong: widget.currentSong,
//           musicService: widget.musicService,
//           onSongPlay: widget.onSongPlay,
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingsTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? textColor,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: textColor ?? Colors.white),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: textColor ?? Colors.white,
//           fontSize: 16,
//         ),
//       ),
//       trailing: Icon(Icons.chevron_right, color: Colors.grey),
//       onTap: onTap,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_player.dart';
import '../services/music_service.dart';
import '../widgets/floating_player_mixin.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? currentSong;
  final Function(Map<String, dynamic>?) onSongPlay;
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
  final User? currentUser = FirebaseAuth.instance.currentUser;

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
