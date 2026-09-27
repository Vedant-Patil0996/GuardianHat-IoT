import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/telemetry_data.dart';
import '../../providers/providers.dart';
import '../widgets/live_clock.dart';

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(telemetryHistoryProvider);

    // Calculate dynamic maxY for distance chart based on current data
    double maxDistance = 100.0;
    if (history.isNotEmpty) {
      final currentMax = history.map((e) => e.distance).reduce(max);
      if (currentMax > 500) {
        maxDistance = 1000.0;
      } else if (currentMax > 250) {
        maxDistance = 500.0;
      } else if (currentMax > 100) {
        maxDistance = 250.0;
      } else if (currentMax > 50) {
        maxDistance = 100.0;
      } else {
        maxDistance = 50.0;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Telemetry History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: const [
          LiveClock(),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                'Waiting for telemetry data...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildChartCard(
                    title: 'Obstacle Distance (cm)',
                    color: AppColors.accent,
                    history: history,
                    yValueMapper: (d) => d.distance,
                    minY: 0,
                    maxY: maxDistance,
                  ),
                  const SizedBox(height: 24),
                  _buildChartCard(
                    title: 'Head Tilt Angle (°)',
                    color: AppColors.warning,
                    history: history,
                    yValueMapper: (d) => d.angle,
                    minY: -180,
                    maxY: 180,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required Color color,
    required List<TelemetryData> history,
    required double Function(TelemetryData) yValueMapper,
    required double minY,
    required double maxY,
  }) {
    final dataPoints = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), yValueMapper(e.value)))
        .toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 60,
                minY: minY,
                maxY: maxY,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
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
                      reservedSize: 22,
                      interval: 15,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox();
                        }
                        final timeStr = DateFormat('HH:mm:ss').format(history[index].timestamp);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withAlpha(76),
                          color.withAlpha(0),
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
        ],
      ),
    );
  }
}
