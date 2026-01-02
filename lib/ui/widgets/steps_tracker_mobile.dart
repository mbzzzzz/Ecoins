// Mobile implementation using health package (HealthKit/Google Fit) with pedometer fallback
import 'dart:async';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class StepsTrackerMobile {
  static int _todaySteps = 0;
  
  // Health Package
  static final Health _health = Health();
  static bool _useHealthPackage = false;
  static Timer? _pollTimer;

  // Pedometer Fallback
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static Function(int)? _onStepsUpdate;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Try Initialize Health (HealthKit / Google Fit)
    try {
      await _initHealth();
    } catch (e) {
      debugPrint('Health init failed: $e');
      _useHealthPackage = false;
    }

    // 2. If Health failed or not authorized, fallback to Pedometer
    if (!_useHealthPackage) {
      debugPrint('Falling back to Pedometer...');
      await _checkPermission();
      await _loadSavedSteps();
      _initPedometer();
    } else {
      // If Health is working, start polling
      _startHealthPolling();
    }
    
    _isInitialized = true;
  }

  // --- HEALTH PACKAGE LOGIC ---

  static Future<void> _initHealth() async {
    // Define the types to get
    var types = [HealthDataType.STEPS];

    // Request access
    // permissions for each type
    var permissions = types.map((e) => HealthDataAccess.READ_WRITE).toList();

    bool requested = await _health.requestAuthorization(types, permissions: permissions);
    
    if (requested) {
      _useHealthPackage = true;
      // Fetch immediate
      await _fetchHealthSteps();
    } else {
      _useHealthPackage = false;
    }
  }

  static Future<void> _fetchHealthSteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      
      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      _todaySteps = steps ?? 0;
      _onStepsUpdate?.call(_todaySteps);
      debugPrint('Health Steps Fetched: $_todaySteps');
    } catch (e) {
      debugPrint('Error fetching health steps: $e');
    }
  }

  static void _startHealthPolling() {
    // Poll every 10 seconds to keep UI updated
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchHealthSteps();
    });
  }

  // --- PEDOMETER FALLBACK LOGIC ---

  static Future<void> _checkPermission() async {
    final status = await Permission.activityRecognition.request();
    if (status.isDenied) {
      debugPrint('Activity Recognition permission denied');
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
        _todaySteps = 0;
        await prefs.setString('steps_date', todayKey);
        await prefs.setInt('steps_today', 0);
        await prefs.remove('steps_offset');
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
    } catch (e) {
      debugPrint('Pedometer initialization error: $e');
    }
  }

  static Future<void> _onStepCount(StepCount event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateTime.now().toIso8601String().split('T')[0];
      final savedDate = prefs.getString('steps_date');
      
      if (savedDate != todayKey) {
        await prefs.setString('steps_date', todayKey);
        await prefs.setInt('steps_today', 0);
        await prefs.setInt('steps_offset', event.steps);
        _todaySteps = 0;
      }
      
      int offset = prefs.getInt('steps_offset') ?? event.steps;
      if (event.steps < offset) {
        offset = 0;
        await prefs.setInt('steps_offset', 0);
      }
      
      if (!prefs.containsKey('steps_offset')) {
         await prefs.setInt('steps_offset', event.steps);
         offset = event.steps;
      }

      int newSteps = event.steps - offset;
      if (newSteps < 0) newSteps = 0;
      
      _todaySteps = newSteps;
      await prefs.setInt('steps_today', _todaySteps);
      _onStepsUpdate?.call(_todaySteps);
      
    } catch (e) {
      debugPrint('Step count processing error: $e');
    }
  }

  static void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  // --- PUBLIC API ---

  static Future<int> getTodaySteps() async {
    if (_useHealthPackage) {
      await _fetchHealthSteps();
    }
    return _todaySteps;
  }

  static void startTracking(Function(int) onUpdate) {
    _onStepsUpdate = onUpdate;
    if (_useHealthPackage) {
       _fetchHealthSteps(); // Initial fetch
       _startHealthPolling(); // Ensure polling is active
    } else {
      onUpdate(_todaySteps);
    }
  }
}
