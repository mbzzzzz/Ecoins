import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';
import 'package:animate_do/animate_do.dart';

class WalkthroughOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const WalkthroughOverlay({
    super.key,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> {
  int _currentStep = 0;
  
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to the Dashboard!',
      'description': 'This is your eco-command center. Track your carbon savings and grow your impact tree.',
      // 'icon': Icons.dashboard_outlined, // Replaced by image
      'imagePath': 'assets/images/icon.png',
      'alignment': Alignment.center,
    },
    {
      'title': 'Quick Actions',
      'description': 'Easily log your sustainable habits from here. Tap + to verify an activity.',
      'icon': Icons.touch_app_outlined,
      'alignment': Alignment.bottomCenter, // Pointing roughly to bottom buttons
    },
    {
      'title': 'Community & Friends',
      'description': 'Compete on leaderboards and chat with friends in the Community tab.',
      'icon': Icons.people_outline,
      'alignment': Alignment.bottomLeft, // Rough position of nav items
      'btn_text': 'Got it!'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Stack(
        children: [
          // Background content "hole" or spotlight could be complex, 
          // keeping it simple with just text overlay for now.
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.end,
                     children: [
                       TextButton(
                         onPressed: widget.onSkip, 
                         child: Text('Skip', style: GoogleFonts.inter(color: Colors.white60))
                       )
                     ],
                   ),
                   const Spacer(),
                   
                   FadeInUp(
                     key: ValueKey(_currentStep),
                     duration: const Duration(milliseconds: 500),
                     child: Container(
                       padding: const EdgeInsets.all(32),
                       decoration: BoxDecoration(
                         color: const Color(0xFF1F2937),
                         borderRadius: BorderRadius.circular(24),
                         border: Border.all(color: Colors.white.withOpacity(0.1)),
                         boxShadow: [
                            BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.1), blurRadius: 30, spreadRadius: 5)
                         ]
                       ),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                             Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: AppTheme.primaryGreen.withOpacity(0.1),
                                 shape: BoxShape.circle
                               ),
                               child: step['imagePath'] != null 
                                 ? Image.asset(step['imagePath'], width: 60, height: 60)
                                 : Icon(step['icon'], color: AppTheme.primaryGreen, size: 40),
                             ),
                           const SizedBox(height: 24),
                           Text(
                             step['title'],
                             style: GoogleFonts.outfit(
                               color: Colors.white,
                               fontSize: 24,
                               fontWeight: FontWeight.bold
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 12),
                           Text(
                             step['description'],
                             style: GoogleFonts.inter(
                               color: Colors.grey[400],
                               fontSize: 16,
                               height: 1.5
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 32),
                           ScaleButton(
                             onTap: () {
                               if (_currentStep < _steps.length - 1) {
                                  setState(() => _currentStep++);
                               } else {
                                  widget.onFinish();
                               }
                             }, 
                             child: Container(
                               width: double.infinity,
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               decoration: BoxDecoration(
                                 color: AppTheme.primaryGreen,
                                 borderRadius: BorderRadius.circular(30)
                               ),
                               alignment: Alignment.center,
                               child: Text(
                                 step['btn_text'] ?? 'Next',
                                 style: GoogleFonts.outfit(
                                   color: Colors.black, // Dark text on green
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16
                                 ),
                               ),
                             )
                           ),
                           if (_currentStep > 0)
                             Padding(
                               padding: const EdgeInsets.only(top: 16.0),
                               child: GestureDetector(
                                 onTap: () => setState(() => _currentStep--),
                                 child: Text('Back', style: GoogleFonts.inter(color: Colors.white54)),
                               ),
                             )
                         ],
                       ),
                     ),
                   ),
                   const Spacer(),
                   // Progress dots
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(_steps.length, (index) {
                       return Container(
                         margin: const EdgeInsets.symmetric(horizontal: 4),
                         width: 8,
                         height: 8,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: index == _currentStep ? AppTheme.primaryGreen : Colors.white24
                         ),
                       );
                     }),
                   ),
                   const SizedBox(height: 20),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
