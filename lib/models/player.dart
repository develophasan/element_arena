import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'element_type.dart';

class Player extends PositionComponent {
  final String id;
  final String name;
  final ElementType elementType;
  ElementStats _baseStats;
  ElementStats _currentStats;
  double health;
  double energy;
  bool isAlive;
  Vector2 velocity;
  final Map<String, Timer> _activeEffects = {};

  Player({
    required this.id,
    required this.name,
    required this.elementType,
    Vector2? position,
    Vector2? size,
  })  : _baseStats = ElementStats.getStatsForElement(elementType),
        _currentStats = ElementStats.getStatsForElement(elementType),
        health = 100.0,
        energy = 100.0,
        isAlive = true,
        velocity = Vector2.zero() {
    this.position = position ?? Vector2.zero();
    this.size = size ?? Vector2(50, 50);
  }

  ElementStats get stats => _currentStats;

  void move(Vector2 direction) {
    velocity = direction * _currentStats.speed;
    position += velocity;
  }

  void takeDamage(double damage, ElementType attackerType) {
    double multiplier = ElementStats.getDamageMultiplier(attackerType, elementType);
    double finalDamage = damage * multiplier / _currentStats.defense;
    health -= finalDamage;
    
    if (health <= 0) {
      health = 0;
      isAlive = false;
    }
  }

  void useSpecialAbility() {
    if (energy >= 30) {
      energy -= 30;
      // Özel yetenek mantığı burada uygulanacak
    }
  }

  void regenerateEnergy(double dt) {
    if (energy < 100) {
      energy = (energy + 5 * dt).clamp(0, 100);
    }
  }

  void addTemporaryEffect(
    String effectId,
    ElementStats Function(ElementStats) modifier,
    Duration duration,
  ) {
    // Eğer aynı efekt zaten varsa, süresini yenile
    _activeEffects[effectId]?.stop();

    // Efekti uygula
    _currentStats = modifier(_currentStats);

    // Süre sonunda efekti kaldır
    _activeEffects[effectId] = Timer(
      duration.inSeconds.toDouble(),
      onTick: () {
        _activeEffects.remove(effectId);
        _recalculateStats();
      },
      repeat: false,
    );
  }

  void _recalculateStats() {
    // Temel statları başlangıç noktası olarak al
    _currentStats = _baseStats;

    // Tüm aktif efektleri uygula
    for (final effect in _activeEffects.entries) {
      _currentStats = effect.value.onTick as ElementStats;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    regenerateEnergy(dt);

    // Aktif efektleri güncelle
    for (final timer in _activeEffects.values) {
      timer.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Oyuncu görsel render işlemleri
    final paint = Paint()..color = _getElementColor();
    canvas.drawRect(size.toRect(), paint);

    // Aktif efektleri göster
    if (_activeEffects.isNotEmpty) {
      final effectPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(size.toRect(), effectPaint);
    }
  }

  Color _getElementColor() {
    switch (elementType) {
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
} 