import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/widgets/glass_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImpactDashboardScreen extends StatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  // Mock Data for Charts
  // In a real app, this would come from Supabase aggregates
  final List<FlSpot> _weeklySpots = const [
    FlSpot(0, 50),
    FlSpot(1, 120),
    FlSpot(2, 90),
    FlSpot(3, 220),
    FlSpot(4, 180),
    FlSpot(5, 300),
    FlSpot(6, 450),
  ];

  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Your Impact',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Carbon Savings Trends'),
                  const SizedBox(height: 12),
                  _buildLineChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Activity Breakdown'),
                  const SizedBox(height: 12),
                  _buildPieChart(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Saved',
            '142 kg',
            Icons.cloud_off,
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Trees Planted',
            '3',
            Icons.forest,
            Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      child: AspectRatio(
        aspectRatio: 1.70,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 100,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[value.toInt()],
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}g',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: 500,
            lineBarsData: [
              LineChartBarData(
                spots: _weeklySpots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppTheme.accentYellow, AppTheme.primaryGreen],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentYellow.withOpacity(0.3),
                      AppTheme.primaryGreen.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: _showingSections(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(AppTheme.primaryGreen, 'Transport', '40%'),
              const SizedBox(height: 8),
              _buildLegendItem(AppTheme.accentYellow, 'Recycle', '30%'),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.orangeAccent, 'Energy', '15%'),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.purpleAccent, 'Food', '15%'),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: AppTheme.primaryGreen,
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: AppTheme.accentYellow,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.orangeAccent,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Colors.purpleAccent,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegendItem(Color color, String text, String pct) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
