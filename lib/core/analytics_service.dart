import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton analytics service that logs events to the `analytics_events`
/// Supabase table.
///
/// Table schema:
///   id          uuid         (default gen_random_uuid())
///   user_id     uuid
///   event_name  text
///   properties  jsonb
///   created_at  timestamptz  (default now())
class AnalyticsService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Canonical accessor: `AnalyticsService.instance`
  static AnalyticsService get instance => _instance;

  // ---------------------------------------------------------------------------
  // Event name constants
  // ---------------------------------------------------------------------------
  static const String activityLogged      = 'activity_logged';
  static const String rewardRedeemed      = 'reward_redeemed';
  static const String levelUp             = 'level_up';
  static const String friendAdded         = 'friend_added';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String referralUsed        = 'referral_used';
  static const String profileEdited       = 'profile_edited';
  static const String appOpened           = 'app_opened';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Tracks [eventName] with optional [properties].
  ///
  /// - Silently no-ops when no authenticated user is present.
  /// - Never throws; all errors are swallowed so analytics cannot crash the app.
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // Do not track anonymous sessions.

      await Supabase.instance.client.from('analytics_events').insert({
        'user_id': user.id,
        'event_name': eventName,
        'properties': properties ?? {},
      });
    } catch (e, st) {
      // Analytics must never surface errors to the caller.
      debugPrint('[AnalyticsService] Failed to track "$eventName": $e\n$st');
    }
  }
}
