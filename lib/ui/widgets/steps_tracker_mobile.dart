// Mobile implementation using pedometer and shared_preferences
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class StepsTrackerMobile {
  static int _todaySteps = 0;
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  static Function(int)? _onStepsUpdate;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Check and request Activity Recognition permission (Android 10+)
    await _checkPermission();
    
    // Initialize SharedPreferences and load saved steps
    await _loadSavedSteps();
    
    // Start listening to Pedometer stream
    _initPedometer();
    
    _isInitialized = true;
  }

  static Future<void> _checkPermission() async {
    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('Activity Recognition permission denied');
      // On some older Android versions it might not be needed, but for safe measure:
      // return; // Don't return, try anyway as some sensors might work or it might be iOS where this perm is different
    }
  }

  static Future<void> _loadSavedSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateTime.now().toIso8601String().split('T')[0];
      final savedDate = prefs.getString('steps_date');
      
      if (savedDate == todayKey) {
        _todaySteps = prefs.getInt('steps_today') ?? 0;
      } else {
        // Reset for new day
        _todaySteps = 0;
        await prefs.setString('steps_date', todayKey);
        await prefs.setInt('steps_today', 0);
        await prefs.remove('steps_offset'); // Reset offset for new day
      }
    } catch (e) {
      debugPrint('Error loading key steps: $e');
    }
  }

  static void _initPedometer() {
    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );
      
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (status) => debugPrint('Pedestrian Status: ${status.status}'),
        onError: (error) => debugPrint('Pedestrian Status Error: $error'),
      );
    } catch (e) {
      debugPrint('Pedometer initialization error: $e');
    }
  }

  static Future<void> _onStepCount(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateTime.now().toIso8601String().split('T')[0];
      final savedDate = prefs.getString('steps_date');
      
      // Handle day change (midnight crossover)
      if (savedDate != todayKey) {
        await prefs.setString('steps_date', todayKey);
        await prefs.setInt('steps_today', 0);
         // Reset offset to current sensor value
        await prefs.setInt('steps_offset', event.steps);
        _todaySteps = 0;
      }
      
      int offset = prefs.getInt('steps_offset') ?? event.steps;
      
      // Detect Reboot (current steps < offset)
      if (event.steps < offset) {
        offset = 0;
        await prefs.setInt('steps_offset', 0);
      }
      
      // If this is the very first time we see steps today and no offset, set offset
      if (!prefs.containsKey('steps_offset')) {
         await prefs.setInt('steps_offset', event.steps);
         offset = event.steps;
      }

      int newSteps = event.steps - offset;
      if (newSteps < 0) newSteps = 0;
      
      _todaySteps = newSteps;
      await prefs.setInt('steps_today', _todaySteps);
      
      debugPrint('Steps Update: $_todaySteps (Sensor: ${event.steps}, Offset: $offset)');
      _onStepsUpdate?.call(_todaySteps);
      
    } catch (e) {
      debugPrint('Step count processing error: $e');
    }
  }

  static void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
    // Fallback?
  }

  static Future<int> getTodaySteps() async {
    return _todaySteps;
  }

  static void startTracking(Function(int) onUpdate) {
    _onStepsUpdate = onUpdate;
    // Pushes immediately current value
    onUpdate(_todaySteps);
  }
}
