import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';

// Conditional import for health package (mobile only)
import 'steps_tracker_mobile.dart' if (dart.library.html) 'steps_tracker_web.dart';

class StepsTrackerWidget extends StatefulWidget {
  const StepsTrackerWidget({super.key});

  @override
  State<StepsTrackerWidget> createState() => _StepsTrackerWidgetState();
}

class _StepsTrackerWidgetState extends State<StepsTrackerWidget> {
  int _currentSteps = 0;
  int _dailyGoal = 10000;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeMobileTracking();
    } else {
      _isLoading = false;
    }
    _loadTodaySteps();
  }

  Future<void> _initializeMobileTracking() async {
    try {
      await StepsTrackerMobile.initialize();
      StepsTrackerMobile.startTracking((steps) {
        if (mounted) {
          setState(() {
            _currentSteps = steps;
            _isTracking = true;
          });
          _saveStepsToDatabase(steps);
        }
      });
      
      final initialSteps = await StepsTrackerMobile.getTodaySteps();
      if (mounted) {
        setState(() {
          _currentSteps = initialSteps;
          _isTracking = true;
          _isLoading = false;
        });
        _saveStepsToDatabase(initialSteps);
      }
    } catch (e) {
      debugPrint('Steps tracking initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTracking = false;
        });
      }
    }
  }

  Future<void> _loadTodaySteps() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from('daily_steps')
          .select()
          .eq('user_id', user.id)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _currentSteps = response['steps'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading steps: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStepsToDatabase(int steps) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      await Supabase.instance.client.from('daily_steps').upsert({
        'user_id': user.id,
        'date': startOfDay.toIso8601String(),
        'steps': steps,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Check if goal reached and award points (only once per day)
      if (steps >= _dailyGoal) {
        await _awardStepsPoints();
      }
    } catch (e) {
      debugPrint('Error saving steps: $e');
    }
  }

  Future<void> _awardStepsPoints() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Check if points already awarded today
      final existing = await Supabase.instance.client
          .from('activities')
          .select()
          .eq('user_id', user.id)
          .eq('category', 'steps')
          .gte('logged_at', startOfDay.toIso8601String())
          .maybeSingle();

      if (existing != null) return; // Already awarded

      // Award 25 points for reaching 10000 steps
      const points = 25;
      const carbonSaved = 0.5; // Approximate carbon saved from walking

      // Create activity
      await Supabase.instance.client.from('activities').insert({
        'user_id': user.id,
        'category': 'steps',
        'description': 'Completed 10,000 steps goal',
        'points_earned': points,
        'carbon_saved': carbonSaved,
        'is_verified': true,
        'logged_at': DateTime.now().toIso8601String(),
      });

      // Update profile
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      await Supabase.instance.client.from('profiles').update({
        'points_balance': (profile['points_balance'] ?? 0) + points,
        'carbon_saved_kg': (profile['carbon_saved_kg'] ?? 0.0) + carbonSaved,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Goal reached! +$points points'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error awarding steps points: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final progress = (_currentSteps / _dailyGoal).clamp(0.0, 1.0);
    final remainingSteps = (_dailyGoal - _currentSteps).clamp(0, _dailyGoal);

    return GestureDetector(
      onTap: () {
        // Navigate to detailed steps screen if needed
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Daily Steps Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Steps: $_currentSteps'),
                Text('Goal: $_dailyGoal steps'),
                Text('Remaining: $remainingSteps steps'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(1)}% Complete'),
                const SizedBox(height: 16),
                const Text('Earn 25 points when you reach 10,000 steps!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk, color: Colors.white, size: 24),
                ),
                const Spacer(),
                if (!_isTracking && !kIsWeb)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Not Tracking',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Daily Steps',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '$_currentSteps / $_dailyGoal',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: AppTheme.primaryGreen,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% • ${remainingSteps > 0 ? "$remainingSteps steps left" : "Goal reached! 🎉"}',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
            ),
            if (progress >= 1.0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+25 points earned!',
                  style: GoogleFonts.inter(
                    color: AppTheme.accentYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Open on Android/iOS for live tracking',
                  style: GoogleFonts.inter(
                    color: AppTheme.accentYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
