import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/element_type.dart';
import '../../models/player.dart';

class AttackAnimation extends SpriteAnimationComponent with HasGameRef {
  final ElementType elementType;
  final Vector2 direction;
  final double damage;
  final String sourceId;

  AttackAnimation({
    required this.elementType,
    required this.direction,
    required this.damage,
    required this.sourceId,
    required Vector2 position,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    // Element tipine göre animasyon dosyasını seç
    String animationPath;
    switch (elementType) {
      case ElementType.fire:
        animationPath = 'images/animations/fire/Fire';
        break;
      case ElementType.water:
        animationPath = 'images/animations/water/Explosion_blue_oval';
        break;
      case ElementType.earth:
        animationPath = 'images/animations/earth/Circle_explosion';
        break;
      case ElementType.air:
        animationPath = 'images/animations/air/Lightning_cycle';
        break;
    }

    // Animasyon karelerini yükle
    final frames = <Sprite>[];
    final frameCount = _getFrameCount();
    
    for (int i = 1; i <= frameCount; i++) {
      final sprite = await gameRef.loadSprite('$animationPath$i.png');
      frames.add(sprite);
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: 0.1,
      loop: false,
    );

    // Animasyon boyutunu ayarla
    size = Vector2(80, 80);

    // Animasyon yönünü ayarla
    angle = direction.angleToSigned(Vector2(1, 0));

    // Animasyon tamamlandığında bileşeni kaldır
    animation?.onComplete = () => removeFromParent();
  }

  int _getFrameCount() {
    switch (elementType) {
      case ElementType.fire:
        return 6;
      case ElementType.water:
        return 10;
      case ElementType.earth:
        return 10;
      case ElementType.air:
        return 6;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Saldırı animasyonunu hareket ettir
    position += direction * 300 * dt;

    // Çarpışma kontrolü
    for (final component in gameRef.children) {
      if (component is Player &&
          component.id != sourceId &&
          component.containsPoint(position)) {
        component.takeDamage(damage, elementType);
        removeFromParent();
        break;
      }
    }
  }
}

class ElementalEffect extends SpriteAnimationComponent with HasGameRef {
  final ElementType elementType;

  ElementalEffect({
    required this.elementType,
    required Vector2 position,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    // Element tipine göre efekt dosyasını seç
    String effectPath;
    switch (elementType) {
      case ElementType.fire:
        effectPath = 'images/animations/effects/Explosion_gas';
        break;
      case ElementType.water:
        effectPath = 'images/animations/effects/Explosion_gas_circle';
        break;
      case ElementType.earth:
        effectPath = 'images/animations/effects/Nuclear_explosion';
        break;
      case ElementType.air:
        effectPath = 'images/animations/effects/Explosion_two_colors';
        break;
    }

    // Efekt karelerini yükle
    final frames = <Sprite>[];
    for (int i = 1; i <= 10; i++) {
      final sprite = await gameRef.loadSprite('$effectPath$i.png');
      frames.add(sprite);
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: 0.08,
      loop: false,
    );

    // Efekt boyutunu ayarla
    size = Vector2(100, 100);

    // Efekt tamamlandığında bileşeni kaldır
    animation?.onComplete = () => removeFromParent();
  }
} 