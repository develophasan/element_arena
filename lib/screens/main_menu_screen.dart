import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'element_selection_screen.dart';
import 'auth/login_screen.dart';
import 'lobby_list_screen.dart';
import 'profile_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final firebaseService = FirebaseService();
    await firebaseService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/menu_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Element Arena',
                style: GoogleFonts.pressStart2p(
                  fontSize: 48,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.blue.shade900,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              _buildMenuButton(
                context,
                'Oyuna Başla',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LobbyListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                'Element Seç',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ElementSelectionScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                'Profil',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                'Çıkış Yap',
                () => _handleLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: GoogleFonts.pressStart2p(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 