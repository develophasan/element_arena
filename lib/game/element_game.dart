import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/element_type.dart';
import '../models/powerup_type.dart';
import 'components/attack_animation.dart';
import 'components/powerup.dart';
import '../services/firebase_service.dart';
import 'dart:math';

class ElementGame extends FlameGame with TapDetector, DragDetector {
  late Player currentPlayer;
  final Map<String, Player> players = {};
  late JoystickComponent joystick;
  Vector2 moveDirection = Vector2.zero();
  Vector2? attackTarget;
  late Timer _powerUpSpawnTimer;
  final Random _random = Random();
  final FirebaseService _firebaseService = FirebaseService();
  final String lobbyId;

  ElementGame({required this.lobbyId});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Arka plan
    add(
      SpriteComponent(
        sprite: await loadSprite('images/backgrounds/game_bg.png'),
        size: size,
      ),
    );

    // Joystick
    final knobPaint = Paint()..color = Colors.blue.withOpacity(0.7);
    final backgroundPaint = Paint()..color = Colors.blueGrey.withOpacity(0.5);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 25, paint: knobPaint),
      background: CircleComponent(radius: 60, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 50, bottom: 50),
    );
    add(joystick);

    // Ses efektleri ve müzik
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([
      'audio/effects/fire_attack.mp3',
      'audio/effects/water_attack.mp3',
      'audio/effects/earth_attack.mp3',
      'audio/effects/air_attack.mp3',
      'audio/effects/player_hit.mp3',
      'audio/effects/player_death.mp3',
      'audio/effects/powerup_collect.mp3',
      'audio/music/game.mp3',
      'audio/music/victory.mp3',
    ]);

    // Oyun müziğini başlat
    FlameAudio.bgm.play('audio/music/game.mp3', volume: 0.5);

    // Güçlendirme zamanlayıcısını başlat
    _powerUpSpawnTimer = Timer(
      8, // Her 8 saniyede bir güçlendirme oluştur
      onTick: _spawnPowerUp,
      repeat: true,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (joystick.direction != Vector2.zero()) {
      moveDirection = joystick.direction;
      currentPlayer.move(moveDirection * dt * 150); // Hareket hızını artırdık
    }

    // Oyuncuların pozisyonlarını güncelle
    for (final player in players.values) {
      player.update(dt);
    }

    // Güçlendirme zamanlayıcısını güncelle
    _powerUpSpawnTimer.update(dt);
  }

  void addPlayer(String id, String name, ElementType elementType) {
    final startPosition = _getRandomStartPosition();
    final player = Player(
      id: id,
      name: name,
      elementType: elementType,
      position: startPosition,
      size: Vector2(60, 60), // Oyuncu boyutunu artırdık
    );
    players[id] = player;
    add(player);

    if (id == currentPlayer.id) {
      currentPlayer = player;
      camera.followComponent(player);
    }
  }

  Vector2 _getRandomStartPosition() {
    final padding = 100.0;
    return Vector2(
      padding + _random.nextDouble() * (size.x - 2 * padding),
      padding + _random.nextDouble() * (size.y - 2 * padding),
    );
  }

  void removePlayer(String id) {
    final player = players.remove(id);
    if (player != null) {
      remove(player);
    }
  }

  void updatePlayerPosition(String id, Vector2 position) {
    final player = players[id];
    if (player != null) {
      player.position = position;
    }
  }

  void playerAttack(String id, Vector2 target) {
    final player = players[id];
    if (player != null && player.energy >= 20) {
      player.energy -= 20;
      
      final direction = (target - player.position).normalized();
      final attackPosition = player.position + direction * 30;

      final attack = AttackAnimation(
        elementType: player.elementType,
        direction: direction,
        damage: player.stats.attackPower,
        sourceId: player.id,
        position: attackPosition,
      );

      add(attack);

      FlameAudio.play(
        'audio/effects/${player.elementType.toString().split('.').last}_attack.mp3',
        volume: 0.8,
      );
    }
  }

  void playerHit(String id, double damage, ElementType attackerType) {
    final player = players[id];
    if (player != null) {
      add(
        ElementalEffect(
          elementType: attackerType,
          position: player.position.clone(),
        ),
      );

      FlameAudio.play('audio/effects/player_hit.mp3', volume: 0.6);
      player.takeDamage(damage, attackerType);

      if (!player.isAlive) {
        playerDeath(id);
      }
    }
  }

  void playerDeath(String id) {
    final player = players[id];
    if (player != null) {
      add(
        ElementalEffect(
          elementType: player.elementType,
          position: player.position.clone(),
        ),
      );

      FlameAudio.play('audio/effects/player_death.mp3', volume: 0.7);
      
      // Ölüm parçacık efekti
      add(
        ParticleSystemComponent(
          position: player.position,
          particle: Particle.generate(
            count: 30,
            lifespan: 1,
            generator: (i) => ParticleComponent(
              child: CircleComponent(
                radius: 3,
                paint: Paint()..color = _getElementColor(player.elementType),
              ),
              velocity: Vector2.random() * 200,
            ),
          ),
        ),
      );

      removePlayer(id);
    }
  }

  Color _getElementColor(ElementType type) {
    switch (type) {
      case ElementType.fire:
        return Colors.red;
      case ElementType.water:
        return Colors.blue;
      case ElementType.earth:
        return Colors.brown;
      case ElementType.air:
        return Colors.white;
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    attackTarget = info.eventPosition.game;
    playerAttack(currentPlayer.id, attackTarget!);
  }

  @override
  void onDragUpdate(DragUpdateInfo info) {
    super.onDragUpdate(info);
    attackTarget = info.eventPosition.game;
  }

  @override
  void onDragEnd(DragEndInfo info) {
    super.onDragEnd(info);
    attackTarget = null;
  }

  void _spawnPowerUp() {
    final powerUpType = PowerUpType.values[_random.nextInt(PowerUpType.values.length)];
    final position = Vector2(
      _random.nextDouble() * size.x,
      _random.nextDouble() * size.y,
    );

    add(PowerUp(
      type: powerUpType,
      position: position,
    ));

    // Güçlendirme spawn efekti
    add(
      ParticleSystemComponent(
        position: position,
        particle: Particle.generate(
          count: 15,
          lifespan: 0.7,
          generator: (i) => ParticleComponent(
            child: CircleComponent(
              radius: 2,
              paint: Paint()..color = Colors.yellow.withOpacity(0.8),
            ),
            velocity: Vector2.random() * 80,
          ),
        ),
      ),
    );
  }

  void endGame(String winnerId) {
    FlameAudio.bgm.stop();
    FlameAudio.play('audio/music/victory.mp3', volume: 0.8);

    final playerIds = players.keys.toList();
    _firebaseService.recordGameResult(lobbyId, winnerId, playerIds);

    final winnerPosition = players[winnerId]?.position ?? size / 2;
    
    // Zafer efekti
    add(
      ParticleSystemComponent(
        position: winnerPosition,
        particle: Particle.generate(
          count: 100,
          lifespan: 3,
          generator: (i) => ParticleComponent(
            child: CircleComponent(
              radius: 4,
              paint: Paint()..color = Colors.yellow.withOpacity(0.8),
            ),
            velocity: Vector2.random() * 300,
          ),
        ),
      ),
    );

    removeAll(children.whereType<PowerUp>());
    removeAll(children.whereType<AttackAnimation>());
  }
} 