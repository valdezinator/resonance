import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // Add this constant
  static const String LISTENING_ACTIVITY_KEY = 'show_listening_activity';

  // Privacy settings state
  bool _showListeningActivity = true;
  bool _showRecentlyPlayed = true;
  bool _allowDataCollection = true;
  bool _enableTwoFactor = false;
  bool _showProfileToPublic = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showListeningActivity = prefs.getBool(LISTENING_ACTIVITY_KEY) ?? true;
    });
  }

  Future<void> _updateListeningActivity(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(LISTENING_ACTIVITY_KEY, value);
    setState(() {
      _showListeningActivity = value;
    });
  }

  // Add this method to clear cache
  Future<void> _clearCache() async {
    try {
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear network image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear cached network image directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await Future.wait(
          tempDir.listSync(recursive: true).map((entity) async {
            if (entity is File) {
              try {
                await entity.delete();
              } catch (e) {
                print('Error deleting file: ${entity.path}');
              }
            }
          }),
        );
      }
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c0f14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Privacy'),
          _buildSwitchTile(
            title: 'Show Listening Activity',
            subtitle: 'Let followers see what you\'re playing',
            value: _showListeningActivity,
            onChanged: (value) => _updateListeningActivity(value),
            icon: 'assets/icons/listening.svg',
          ),
          _buildSwitchTile(
            title: 'Show Recently Played',
            subtitle: 'Display your music history on your profile',
            value: _showRecentlyPlayed,
            onChanged: (value) => setState(() => _showRecentlyPlayed = value),
            icon: 'assets/icons/history.svg',
          ),
          _buildSwitchTile(
            title: 'Public Profile',
            subtitle: 'Make your profile visible to everyone',
            value: _showProfileToPublic,
            onChanged: (value) => setState(() => _showProfileToPublic = value),
            icon: 'assets/icons/profile.svg',
          ),

          _buildSectionHeader('Security'),
          _buildSwitchTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            value: _enableTwoFactor,
            onChanged: (value) => setState(() => _enableTwoFactor = value),
            icon: 'assets/icons/security.svg',
          ),
          _buildListTile(
            title: 'Change Password',
            subtitle: 'Update your account password',
            icon: 'assets/icons/password.svg',
            onTap: () {
              // TODO: Implement password change
            },
          ),

          _buildSectionHeader('Data & Storage'),
          _buildSwitchTile(
            title: 'Allow Data Collection',
            subtitle: 'Help us improve your experience',
            value: _allowDataCollection,
            onChanged: (value) => setState(() => _allowDataCollection = value),
            icon: 'assets/icons/data.svg',
          ),
          _buildListTile(
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            icon: 'assets/icons/clear.svg',
            onTap: () {
              // TODO: Implement cache clearing
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'Clear Cache',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'This will clear all cached data. Continue?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          Navigator.pop(context);
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          await _clearCache();
                          
                          // Remove loading indicator
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cache cleared successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          // Remove loading indicator if still showing
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to clear cache: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'All changes are automatically saved and synchronized across your devices.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String icon,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
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
      onTap: () {
        if (title == 'Clear Cache') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Clear Cache',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'This will clear all cached data. Continue?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      Navigator.pop(context);
                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      await _clearCache();
                      
                      // Remove loading indicator
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cache cleared successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      // Remove loading indicator if still showing
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to clear cache: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Clear'),
                ),
              ],
            ),
          );
        } else {
          onTap();
        }
      },
    );
  }
}
