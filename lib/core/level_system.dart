class LevelSystem {
  static const List<LevelData> levels = [
    // Early Growth
    LevelData(name: 'Seedling', minPoints: 0, maxPoints: 499, assetPath: 'assets/images/tree_stage_1.png'),
    LevelData(name: 'Sprout', minPoints: 500, maxPoints: 1499, assetPath: 'assets/images/tree_stage_2.png'),
    LevelData(name: 'Sapling', minPoints: 1500, maxPoints: 3499, assetPath: 'assets/images/tree_stage_3.png'),
    
    // Maturing
    LevelData(name: 'Young Tree', minPoints: 3500, maxPoints: 7499, assetPath: 'assets/images/tree_stage_4.png'),
    LevelData(name: 'Small Oak', minPoints: 7500, maxPoints: 14999, assetPath: 'assets/images/tree_stage_5.png'),
    LevelData(name: 'Growing Oak', minPoints: 15000, maxPoints: 29999, assetPath: 'assets/images/tree_stage_6.png'),
    
    // Established
    LevelData(name: 'Strong Oak', minPoints: 30000, maxPoints: 59999, assetPath: 'assets/images/tree_stage_7.png'),
    LevelData(name: 'Mature Tree', minPoints: 60000, maxPoints: 119999, assetPath: 'assets/images/tree_stage_8.png'),
    LevelData(name: 'Ancient Oak', minPoints: 120000, maxPoints: 249999, assetPath: 'assets/images/tree_stage_9.png'),
    
    // Legendary
    LevelData(name: 'Elder Tree', minPoints: 250000, maxPoints: 499999, assetPath: 'assets/images/tree_stage_10.png'),
    LevelData(name: 'Spirit of Forest', minPoints: 500000, maxPoints: 999999, assetPath: 'assets/images/tree_stage_11.png'),
    LevelData(name: 'World Tree', minPoints: 1000000, maxPoints: 999999999, assetPath: 'assets/images/tree_stage_12.png'),
  ];

  static LevelData getLevel(int points) {
    // Returns the highest level where minPoints <= userPoints
    return levels.lastWhere(
      (level) => points >= level.minPoints,
      orElse: () => levels.first,
    );
  }
  
  static LevelData getNextLevel(int points) {
    final current = getLevel(points);
    final index = levels.indexOf(current);
    if (index < levels.length - 1) {
      return levels[index + 1];
    }
    return current; // Is already Max level
  }
  
  static double getProgress(int points) {
    final current = getLevel(points);
    final next = getNextLevel(points);
    
    if (current == next) return 1.0; // Max level
    
    final range = next.minPoints - current.minPoints;
    final progressInLevel = points - current.minPoints;
    
    return (progressInLevel / range).clamp(0.0, 1.0);
  }
}

class LevelData {
  final String name;
  final int minPoints;
  final int maxPoints;
  final String assetPath;

  const LevelData({
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.assetPath,
  });
}
