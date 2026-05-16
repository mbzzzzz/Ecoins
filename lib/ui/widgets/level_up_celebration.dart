import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:ecoins/core/level_system.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class LevelUpCelebration extends StatefulWidget {
  final LevelData newLevel;
  final VoidCallback onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.92),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ], 
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    'LEVEL UP!',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentYellow,
                      letterSpacing: 2,
                      shadows: [
                        BoxShadow(
                          color: AppTheme.accentYellow.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 10
                        )
                      ]
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Tree Image
                ZoomIn(
                  delay: const Duration(milliseconds: 300),
                   duration: const Duration(milliseconds: 800),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                           color: AppTheme.primaryGreen.withOpacity(0.4),
                           blurRadius: 50,
                           spreadRadius: 10
                         )
                      ]
                    ),
                    // Use a placeholder icon if asset not ready, but we should try to use the asset path
                    child: Image.asset(
                      widget.newLevel.assetPath,
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                         return const Icon(Icons.park, size: 150, color: AppTheme.primaryGreen);
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Text(
                    'You are now a',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Text(
                    widget.newLevel.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 1000),
                  child: ScaleButton(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(30),
                         boxShadow: [
                           BoxShadow(
                             color: AppTheme.primaryGreen.withOpacity(0.4),
                             blurRadius: 15,
                             offset: const Offset(0, 5)
                           )
                         ]
                      ),
                      child: Text(
                        'Awesome!',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
