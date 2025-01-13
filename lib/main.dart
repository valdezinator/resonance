import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'config/supabase_config.dart';
import 'login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/auth_config.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize Supabase
    await supabase.Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const AuthApp(),
      ),
    );
  } catch (e) {
    print('Initialization error: $e');
    rethrow;
  }
}

class AuthApp extends StatelessWidget {
  const AuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Resonance',
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: themeProvider.backgroundColor,
            textTheme: GoogleFonts.montserratTextTheme(),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        // If we have a user, go to MyApp, otherwise go to SignInPage
        if (snapshot.hasData && snapshot.data != null) {
          return MyApp(user: snapshot.data);
        }
        
        return const SignInPage();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            // Image.asset('assets/images/logo.png', height: 100),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    clientId: AuthConfig.androidClientId,  // Use Android client ID for mobile
    serverClientId: AuthConfig.googleClientId,  // Use Web client ID for server
  );
  bool _isSigningIn = false;

  Future<User?> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isSigningIn = true;
      });

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Sign in cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        try {
          final supabaseClient = supabase.Supabase.instance.client;

          // Sign in with Supabase first
          final supabaseAuthResponse = await supabaseClient.auth.signInWithIdToken(
            provider: supabase.OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken,
          );

          if (supabaseAuthResponse.session != null) {
            final userId = supabaseAuthResponse.session!.user.id;
            
            // Create or update user record in public.users table
            await supabaseClient
                .from('users')
                .upsert({
                  'id': userId,
                  'display_name': firebaseUser.displayName ?? '',
                  'photo_url': firebaseUser.photoURL ?? '',
                  'firebase_uid': firebaseUser.uid,
                }, onConflict: 'id');

            print('User record created/updated in public.users table');
            
            // Update or create user data
            await supabaseClient.auth.updateUser(supabase.UserAttributes(
              data: {
                'display_name': firebaseUser.displayName ?? '',
                'photo_url': firebaseUser.photoURL ?? '',
                'firebase_uid': firebaseUser.uid,
                'last_sign_in': DateTime.now().toIso8601String(),
              },
            ));

            print('Supabase session established: ${supabaseAuthResponse.session?.user.id}');
          }

          // Continue with navigation...
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MyApp(user: firebaseUser),
              ),
            );
          }
        } catch (e) {
          print('Detailed Supabase error: $e');
          // Continue with Firebase auth even if Supabase fails
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MyApp(user: firebaseUser),
              ),
            );
          }
        }
      }

      return firebaseUser;
    } catch (e) {
      print('Error during Google sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Sign In',
                style: GoogleFonts.montserrat().copyWith(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: GoogleFonts.montserrat().copyWith(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final user = await _handleGoogleSignIn();
                    if (user != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign in successful')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                icon: SvgPicture.asset(
                  'assets/icons/google_icon.svg',
                  height: 24,
                ),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.grey[900],
                ),
                child: const Text('Forgot Password'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// For signing out
// Future<void> signOut() async {
//   await FirebaseAuth.instance.signOut();
//   await FirebaseAuth.instance.signOut();
//   await GoogleSignIn().signOut();
// }
//   await GoogleSignIn().signOut();
// }