import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarbonMethodologyScreen extends StatelessWidget {
  const CarbonMethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Our Carbon Math',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green hero header
            _buildHeader(),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSection(
                    context,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    icon: Icons.smart_toy_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'AI Verification',
                    child: Text(
                      'Every activity you log is reviewed by our AI to ensure accuracy. '
                      'It assigns points and carbon values based on scientific emission factors.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    context,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    icon: Icons.bolt_outlined,
                    iconColor: const Color(0xFFFDE047),
                    title: 'Emission Factors',
                    child: _buildEmissionTable(textPrimary, textSecondary, dividerColor),
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    context,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    icon: Icons.library_books_outlined,
                    iconColor: const Color(0xFF60A5FA),
                    title: 'Data Sources',
                    child: Text(
                      'We use IPCC 2023 emission factors, UK DEFRA greenhouse gas reporting, '
                      'and EPA emission factors for our baseline calculations.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    context,
                    cardColor: cardColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFFF97316),
                    title: 'Disclaimer',
                    child: Text(
                      'Carbon estimates are approximations. Actual impact may vary based on '
                      'local energy grids, transportation modes, and individual behavior.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'How we calculate your\nenvironmental impact',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transparent science-backed methodology',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: dividerColor),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmissionTable(
    Color textPrimary,
    Color textSecondary,
    Color dividerColor,
  ) {
    final rows = [
      _EmissionRow(emoji: '🚗', label: 'Car trip avoided', value: '2.3 kg CO₂'),
      _EmissionRow(emoji: '🚲', label: 'Cycling instead of driving', value: '0.21 kg/km CO₂'),
      _EmissionRow(emoji: '♻️', label: 'Recycling 1 kg', value: '0.5 kg CO₂'),
      _EmissionRow(emoji: '🥗', label: 'Plant-based meal vs meat', value: '1.5 kg CO₂'),
    ];

    return Column(
      children: rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(row.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      row.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1) Divider(height: 1, color: dividerColor),
          ],
        );
      }).toList(),
    );
  }
}

class _EmissionRow {
  final String emoji;
  final String label;
  final String value;

  const _EmissionRow({
    required this.emoji,
    required this.label,
    required this.value,
  });
}
