import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Color> _accentColors = const [
    Color(0xFF10B981), // Emerald (Default)
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    // Access the notifier and current color
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Choose a color accent for the entire app.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _accentColors.map((color) {
                    final isSelected = themeNotifier.primaryColor == color;
                    return GestureDetector(
                      onTap: () => themeNotifier.setPrimaryColor(color),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(color: Colors.transparent),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white) 
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
           _buildSectionCard(
             child: Column(
               children: const [
                 ListTile(
                   contentPadding: EdgeInsets.zero,
                   title: Text('Version'),
                   trailing: Text('1.0.0'),
                 ),
                 Divider(),
                 ListTile(
                   contentPadding: EdgeInsets.zero,
                   title: Text('Terms of Service'),
                   trailing: Icon(Icons.chevron_right),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: child,
    );
  }
}
