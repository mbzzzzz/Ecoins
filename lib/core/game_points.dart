class GamePoints {
  // Base Points & Multipliers
  static const int verifiedBonus = 50;

  // Category: Transport (Biking/Walking/Public Transit)
  // Assumption: Replaces a car trip. Avg car emits ~0.2kg CO2/km.
  static const double transportCo2PerUnit = 0.2; 
  static const int transportPointsPerUnit = 10; 
  static const String transportUnit = 'km';

  // Category: Food (Plant-based meal)
  // Assumption: Plant based meal saves ~1.5kg CO2 vs meat meal.
  // We treat the slider as "Meal Size/Impact" (1=Snack, 2=Meal, 3=Feast)
  static const double foodCo2PerUnit = 0.8; 
  static const int foodPointsPerUnit = 25;
  static const String foodUnit = 'impact level';

  // Category: Recycle
  // Assumption: ~0.1kg CO2 saved per plastic bottle/can recycled.
  static const double recycleCo2PerUnit = 0.1;
  static const int recyclePointsPerUnit = 5;
  static const String recycleUnit = 'items';

  // Category: Energy (Unplugging, Line Drying, LED switch)
  // Assumption: Variable. Averaging 0.5kg per action.
  static const double energyCo2PerUnit = 0.5;
  static const int energyPointsPerUnit = 20;
  static const String energyUnit = 'action level';

  // Category: Shopping (Eco-friendly products, second-hand)
  // Assumption: Buying used saves ~5-10kg CO2 (clothing). 
  // Scaled down for general "eco purchase".
  static const double shoppingCo2PerUnit = 2.0;
  static const int shoppingPointsPerUnit = 40;
  static const String shoppingUnit = 'item';

  // Category: Steps (Daily Goal)
  static const int stepsGoal = 10000;
  static const int stepsDailyPoints = 25;
  static const double stepsDailyCo2 = 0.8; // ~8km * ~100g/km saved vs car

  static Map<String, dynamic> calculate(String category, double sliderValue) {
    double co2 = 0;
    int points = 0;
    String label = '';

    switch (category) {
      case 'transport':
        // Slider 1-10 maps to 2km - 20km
        double distance = sliderValue * 2; 
        co2 = distance * transportCo2PerUnit;
        points = (distance * transportPointsPerUnit).toInt();
        label = '${distance.toInt()} km';
        break;
      
      case 'food':
        // Slider 1-3 maps to Meal sizes
        int size = ((sliderValue / 10) * 3).ceil().clamp(1, 3);
        co2 = size * foodCo2PerUnit;
        points = size * foodPointsPerUnit;
        List<String> sizes = ['Snack', 'Meal', 'Feast'];
        label = sizes[size - 1];
        break;

      case 'recycle':
        // Slider 1-10 maps to 1-10 items (or bundles)
        int items = sliderValue.toInt();
        // Maybe scale it: Slider 1 = 1 item, Slider 10 = Bag full (10+ items)
        co2 = items * recycleCo2PerUnit;
        points = items * recyclePointsPerUnit;
        label = '$items items';
        break;

      case 'energy':
        // Slider 1-5
        int level = ((sliderValue / 10) * 5).ceil().clamp(1, 5);
        co2 = level * energyCo2PerUnit;
        points = level * energyPointsPerUnit;
        label = 'Level $level';
        break;

      case 'shopping':
        // Single item usually
        co2 = shoppingCo2PerUnit;
        points = shoppingPointsPerUnit;
        label = '1 Purchase';
        break;
        
      default:
        co2 = 0.5;
        points = 10;
        label = 'Activity';
    }

    return {
      'co2_saved': double.parse(co2.toStringAsFixed(2)),
      'points': points,
      'label': label,
    };
  }
}
