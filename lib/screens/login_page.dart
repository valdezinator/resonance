import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/audio_player_widget.dart';

class LoginPage extends StatelessWidget {
  final User? user;

  const LoginPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0F14),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Resonance'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            // Main content area
            const Center(
              child: Text('Welcome to Resonance!', style: TextStyle(color: Colors.white)),
            ),
            
            // Audio player at the bottom
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AudioPlayerWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
