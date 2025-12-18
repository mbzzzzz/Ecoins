// Web implementation - no-op since health package doesn't work on web
class StepsTrackerMobile {
  static Future<void> initialize() async {
    // No-op for web
  }

  static Future<int> getTodaySteps() async {
    return 0;
  }

  static void startTracking(Function(int) onUpdate) {
    // No-op for web
  }
}
