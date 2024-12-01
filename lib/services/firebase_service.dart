import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Authentication işlemleri
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Profil işlemleri
  Future<void> createUserProfile(String userId, String username) async {
    await _database.ref('profiles/$userId').set({
      'username': username,
      'createdAt': ServerValue.timestamp,
      'totalGames': 0,
      'wins': 0,
      'selectedElement': null,
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _database.ref('profiles/$userId').update(data);
  }

  // Lobi işlemleri
  Future<String> createLobby(String hostId, String lobbyName) async {
    final newLobbyRef = _database.ref('lobbies').push();
    await newLobbyRef.set({
      'name': lobbyName,
      'hostId': hostId,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'players': {
        hostId: {
          'ready': false,
          'element': null,
        },
      },
    });
    return newLobbyRef.key!;
  }

  Future<void> joinLobby(String lobbyId, String playerId) async {
    await _database.ref('lobbies/$lobbyId/players/$playerId').set({
      'ready': false,
      'element': null,
    });
  }

  Future<void> leaveLobby(String lobbyId, String playerId) async {
    await _database.ref('lobbies/$lobbyId/players/$playerId').remove();
  }

  Future<void> setPlayerReady(
    String lobbyId,
    String playerId,
    String element,
  ) async {
    await _database.ref('lobbies/$lobbyId/players/$playerId').update({
      'ready': true,
      'element': element,
    });
  }

  // Oyun işlemleri
  Future<void> updatePlayerPosition(
    String lobbyId,
    String playerId,
    double x,
    double y,
  ) async {
    await _database.ref('lobbies/$lobbyId/arena/players/$playerId/position').set({
      'x': x,
      'y': y,
    });
  }

  Future<void> updatePlayerHealth(
    String lobbyId,
    String playerId,
    double health,
  ) async {
    await _database.ref('lobbies/$lobbyId/arena/players/$playerId/health')
        .set(health);
  }

  Future<void> recordGameResult(
    String lobbyId,
    String winnerId,
    List<String> playerIds,
  ) async {
    final gameRef = _database.ref('games').push();
    await gameRef.set({
      'lobbyId': lobbyId,
      'winnerId': winnerId,
      'players': playerIds,
      'timestamp': ServerValue.timestamp,
    });

    // Kazanan oyuncunun skorunu güncelle
    await _database.ref('profiles/$winnerId').update({
      'wins': ServerValue.increment(1),
      'totalGames': ServerValue.increment(1),
    });

    // Diğer oyuncuların toplam oyun sayısını güncelle
    for (String playerId in playerIds) {
      if (playerId != winnerId) {
        await _database.ref('profiles/$playerId').update({
          'totalGames': ServerValue.increment(1),
        });
      }
    }
  }

  // Stream'ler
  Stream<DatabaseEvent> lobbyStream(String lobbyId) {
    return _database.ref('lobbies/$lobbyId').onValue;
  }

  Stream<DatabaseEvent> lobbiesStream() {
    return _database.ref('lobbies').orderByChild('createdAt').onValue;
  }

  Stream<DatabaseEvent> playerPositionsStream(String lobbyId) {
    return _database.ref('lobbies/$lobbyId/arena/players').onValue;
  }

  Stream<DatabaseEvent> userProfileStream(String userId) {
    return _database.ref('profiles/$userId').onValue;
  }
} 