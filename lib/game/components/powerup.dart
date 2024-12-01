import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/powerup_type.dart';
import '../../models/player.dart';

class PowerUp extends SpriteComponent with HasGameRef {
  final PowerUpType type;
  final PowerUpStats stats;
  bool isCollected = false;

  PowerUp({
    required this.type,
    required Vector2 position,
  })  : stats = PowerUpStats.getStatsForType(type),
        super(position: position);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(stats.imagePath);
    size = Vector2(32, 32);

    // Yüzen animasyon efekti
    add(
      MoveEffect.by(
        Vector2(0, -10),
        EffectController(
          duration: 1,
          reverseDuration: 1,
          infinite: true,
        ),
      ),
    );

    // Dönme animasyon efekti
    add(
      RotateEffect.by(
        1,
        EffectController(
          duration: 2,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isCollected) {
      for (final component in gameRef.children) {
        if (component is Player && component.containsPoint(position)) {
          _applyPowerUp(component);
          isCollected = true;
          _playCollectEffect();
          removeFromParent();
          break;
        }
      }
    }
  }

  void _applyPowerUp(Player player) {
    switch (type) {
      case PowerUpType.attackBoost:
        player.addTemporaryEffect(
          'attackBoost',
          (stats) => stats.copyWith(
            attackPower: stats.attackPower * this.stats.value,
          ),
          stats.duration,
        );
        break;
      case PowerUpType.speedBoost:
        player.addTemporaryEffect(
          'speedBoost',
          (stats) => stats.copyWith(
            speed: stats.speed * this.stats.value,
          ),
          stats.duration,
        );
        break;
      case PowerUpType.healthBoost:
        player.health = (player.health + stats.value).clamp(0, 100);
        break;
      case PowerUpType.shieldBoost:
        player.addTemporaryEffect(
          'shieldBoost',
          (stats) => stats.copyWith(
            defense: stats.defense * (1 + this.stats.value),
          ),
          stats.duration,
        );
        break;
      case PowerUpType.elementalPower:
        player.addTemporaryEffect(
          'elementalPower',
          (stats) => stats.copyWith(
            attackPower: stats.attackPower * this.stats.value,
            specialAbilityCooldown: stats.specialAbilityCooldown * 0.5,
          ),
          stats.duration,
        );
        break;
    }
  }

  void _playCollectEffect() {
    // Toplama efekti animasyonu
    gameRef.add(
      ParticleSystemComponent(
        position: position,
        particle: Particle.generate(
          count: 20,
          lifespan: 0.5,
          generator: (i) => ParticleComponent(
            child: CircleComponent(
              radius: 2,
              paint: Paint()..color = _getParticleColor(),
            ),
            velocity: Vector2.random() * 100,
          ),
        ),
      ),
    );

    // Toplama sesi
    FlameAudio.play('effects/powerup_collect.mp3');
  }

  Color _getParticleColor() {
    switch (type) {
      case PowerUpType.attackBoost:
        return Colors.red;
      case PowerUpType.speedBoost:
        return Colors.yellow;
      case PowerUpType.healthBoost:
        return Colors.green;
      case PowerUpType.shieldBoost:
        return Colors.blue;
      case PowerUpType.elementalPower:
        return Colors.purple;
    }
  }
} 