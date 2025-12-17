// Mobile implementation using health package
import 'package:health/health.dart';

class StepsTrackerMobile {
  static Health? _health;
  static Function(int)? _onStepsUpdate;

  static Future<void> initialize() async {
    _health = Health();
    
    // Request permissions
    final types = [HealthDataType.STEPS];
    final permissions = await _health?.requestAuthorization(types);
    
    if (permissions != true) {
      throw Exception('Health permissions not granted');
    }
  }

  static Future<int> getTodaySteps() async {
    if (_health == null) return 0;
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      final stepsData = await _health?.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [HealthDataType.STEPS],
      );
      
      if (stepsData == null || stepsData.isEmpty) return 0;
      
      int totalSteps = 0;
      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }
      
      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  static void startTracking(Function(int) onUpdate) {
    _onStepsUpdate = onUpdate;
    _refreshStepsPeriodically();
  }

  static void _refreshStepsPeriodically() async {
    while (_onStepsUpdate != null) {
      await Future.delayed(const Duration(seconds: 30));
      if (_onStepsUpdate != null) {
        final steps = await getTodaySteps();
        _onStepsUpdate?.call(steps);
      }
    }
  }
}
