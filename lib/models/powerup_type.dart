enum PowerUpType {
  attackBoost,
  speedBoost,
  healthBoost,
  shieldBoost,
  elementalPower,
}

class PowerUpStats {
  final String name;
  final String description;
  final String imagePath;
  final Duration duration;
  final double value;

  const PowerUpStats({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.duration,
    required this.value,
  });

  static PowerUpStats getStatsForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.attackBoost:
        return const PowerUpStats(
          name: 'Saldırı Güçlendirmesi',
          description: 'Saldırı gücünü artırır',
          imagePath: 'assets/images/powerups/attack_boost.png',
          duration: Duration(seconds: 10),
          value: 1.5, // %50 artış
        );
      case PowerUpType.speedBoost:
        return const PowerUpStats(
          name: 'Hız Güçlendirmesi',
          description: 'Hareket hızını artırır',
          imagePath: 'assets/images/powerups/speed_boost.png',
          duration: Duration(seconds: 8),
          value: 1.3, // %30 artış
        );
      case PowerUpType.healthBoost:
        return const PowerUpStats(
          name: 'Can Güçlendirmesi',
          description: 'Canı yeniler',
          imagePath: 'assets/images/powerups/health_boost.png',
          duration: Duration(seconds: 0), // Anlık etki
          value: 30.0, // 30 can yenileme
        );
      case PowerUpType.shieldBoost:
        return const PowerUpStats(
          name: 'Kalkan Güçlendirmesi',
          description: 'Geçici koruma kalkanı sağlar',
          imagePath: 'assets/images/powerups/shield_boost.png',
          duration: Duration(seconds: 5),
          value: 0.5, // %50 hasar azaltma
        );
      case PowerUpType.elementalPower:
        return const PowerUpStats(
          name: 'Elementel Güç',
          description: 'Element gücünü artırır',
          imagePath: 'assets/images/powerups/elemental_power.png',
          duration: Duration(seconds: 12),
          value: 2.0, // %100 element hasarı artışı
        );
    }
  }
} 