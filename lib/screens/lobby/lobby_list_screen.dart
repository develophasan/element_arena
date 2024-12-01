import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/firebase_service.dart';
import 'lobby_screen.dart';

class LobbyListScreen extends StatefulWidget {
  const LobbyListScreen({super.key});

  @override
  State<LobbyListScreen> createState() => _LobbyListScreenState();
}

class _LobbyListScreenState extends State<LobbyListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _lobbyNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/lobby_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Lobiler',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _showCreateLobbyDialog,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _firebaseService.lobbiesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final lobbies = <String, dynamic>{};
                    final DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                    
                    if (dataSnapshot.value != null) {
                      (dataSnapshot.value as Map).forEach((key, value) {
                        lobbies[key.toString()] = value;
                      });
                    }

                    if (lobbies.isEmpty) {
                      return Center(
                        child: Text(
                          'Henüz lobi yok',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: lobbies.length,
                      itemBuilder: (context, index) {
                        final lobbyId = lobbies.keys.elementAt(index);
                        final lobby = lobbies[lobbyId] as Map;
                        final playerCount = (lobby['players'] as Map?)?.length ?? 0;

                        return Card(
                          color: Colors.black.withOpacity(0.7),
                          child: ListTile(
                            title: Text(
                              lobby['name'] ?? 'İsimsiz Lobi',
                              style: GoogleFonts.pressStart2p(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Oyuncular: $playerCount/4',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: playerCount < 4
                                  ? () => _joinLobby(lobbyId)
                                  : null,
                              child: Text(
                                playerCount < 4 ? 'Katıl' : 'Dolu',
                                style: GoogleFonts.pressStart2p(fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateLobbyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Lobi Oluştur',
          style: GoogleFonts.pressStart2p(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _lobbyNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Lobi Adı',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.pressStart2p(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () async {
              if (_lobbyNameController.text.isNotEmpty) {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  final lobbyId = await _firebaseService.createLobby(
                    userId,
                    _lobbyNameController.text,
                  );
                  _lobbyNameController.clear();
                  if (mounted) {
                    Navigator.pop(context);
                    _navigateToLobby(lobbyId);
                  }
                }
              }
            },
            child: Text(
              'Oluştur',
              style: GoogleFonts.pressStart2p(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _joinLobby(String lobbyId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _firebaseService.joinLobby(lobbyId, userId);
      _navigateToLobby(lobbyId);
    }
  }

  void _navigateToLobby(String lobbyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(lobbyId: lobbyId),
      ),
    );
  }
} 