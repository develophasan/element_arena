import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_service.dart';
import '../models/element_type.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final database = FirebaseDatabase.instance;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/menu_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: database.ref('profiles/${user?.uid}').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(
                  child: Text(
                    'Profil bulunamadı',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final profileData =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: _getElementColor(
                        profileData['selectedElement']?.toString(),
                      ),
                      child: Icon(
                        _getElementIcon(
                          profileData['selectedElement']?.toString(),
                        ),
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profileData['username'] ?? 'İsimsiz Oyuncu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildStatCard(
                      'İstatistikler',
                      [
                        _buildStat(
                          'Toplam Oyun',
                          profileData['totalGames']?.toString() ?? '0',
                        ),
                        _buildStat(
                          'Kazanılan',
                          profileData['wins']?.toString() ?? '0',
                        ),
                        _buildStat(
                          'Kazanma Oranı',
                          _calculateWinRate(
                            profileData['wins'] ?? 0,
                            profileData['totalGames'] ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      'Son Oyunlar',
                      [
                        _buildGameHistory(context, database, user?.uid),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, List<Widget> children) {
    return Card(
      color: Colors.black.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHistory(
    BuildContext context,
    FirebaseDatabase database,
    String? userId,
  ) {
    if (userId == null) return const SizedBox();

    return SizedBox(
      height: 200,
      child: StreamBuilder<DatabaseEvent>(
        stream: database
            .ref('games')
            .orderByChild('timestamp')
            .limitToLast(5)
            .onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text(
                'Henüz oyun geçmişi yok',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final games = (snapshot.data!.snapshot.value as Map<dynamic, dynamic>)
              .entries
              .where((game) =>
                  (game.value['players'] as List<dynamic>).contains(userId))
              .toList()
            ..sort((a, b) => (b.value['timestamp'] as int)
                .compareTo(a.value['timestamp'] as int));

          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index].value as Map<dynamic, dynamic>;
              final isWinner = game['winnerId'] == userId;

              return ListTile(
                leading: Icon(
                  isWinner ? Icons.emoji_events : Icons.close,
                  color: isWinner ? Colors.yellow : Colors.red,
                ),
                title: Text(
                  isWinner ? 'Galibiyet' : 'Mağlubiyet',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _formatDate(game['timestamp'] as int),
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _calculateWinRate(int wins, int totalGames) {
    if (totalGames == 0) return '%0';
    return '%${((wins / totalGames) * 100).toStringAsFixed(1)}';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Color _getElementColor(String? elementStr) {
    if (elementStr == null) return Colors.grey;
    final element = ElementType.values.firstWhere(
      (e) => e.toString() == elementStr,
      orElse: () => ElementType.fire,
    );
    switch (element) {
      case ElementType.fire:
        return Colors.red;
      case ElementType.water:
        return Colors.blue;
      case ElementType.earth:
        return Colors.brown;
      case ElementType.air:
        return Colors.grey;
    }
  }

  IconData _getElementIcon(String? elementStr) {
    if (elementStr == null) return Icons.question_mark;
    final element = ElementType.values.firstWhere(
      (e) => e.toString() == elementStr,
      orElse: () => ElementType.fire,
    );
    switch (element) {
      case ElementType.fire:
        return Icons.local_fire_department;
      case ElementType.water:
        return Icons.water_drop;
      case ElementType.earth:
        return Icons.landscape;
      case ElementType.air:
        return Icons.air;
    }
  }
} 