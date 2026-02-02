import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../constants/app_theme.dart';

/// FFT Spectrum chart widget
class SpectrumChart extends StatelessWidget {
  final List<double> data;
  final List<double> frequencyAxis;
  final String title;
  final double? maxFrequency;
  final List<double>? markerFrequencies;
  final List<String>? markerLabels;
  
  const SpectrumChart({
    super.key,
    required this.data,
    required this.frequencyAxis,
    this.title = 'FFT Spectrum',
    this.maxFrequency,
    this.markerFrequencies,
    this.markerLabels,
  });
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }
    
    final maxFreq = maxFrequency ?? (frequencyAxis.isNotEmpty ? frequencyAxis.last : 100);
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.1;
    
    // Prepare spots
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length && i < frequencyAxis.length; i++) {
      if (frequencyAxis[i] <= maxFreq) {
        spots.add(FlSpot(frequencyAxis[i], data[i]));
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '0 - ${maxFreq.toStringAsFixed(0)} Hz',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 4,
                  verticalInterval: maxFreq / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxFreq / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: const Text(
                      'Frequency (Hz)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAxisValue(value),
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.chartGrid),
                ),
                minX: 0,
                maxX: maxFreq,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppTheme.chartLine,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.chartFill,
                    ),
                  ),
                ],
                extraLinesData: _buildMarkerLines(maxY),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppTheme.surfaceLight,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.x.toStringAsFixed(1)} Hz\n${_formatAxisValue(spot.y)}',
                          const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          if (markerFrequencies != null && markerLabels != null)
            _buildMarkerLegend(),
        ],
      ),
    );
  }
  
  ExtraLinesData _buildMarkerLines(double maxY) {
    if (markerFrequencies == null) return ExtraLinesData(verticalLines: []);
    
    final colors = [
      AppTheme.statusGood,
      AppTheme.statusSatisfactory,
      AppTheme.statusUnsatisfactory,
      AppTheme.statusUnacceptable,
    ];
    
    final lines = <VerticalLine>[];
    for (int i = 0; i < markerFrequencies!.length; i++) {
      lines.add(VerticalLine(
        x: markerFrequencies![i],
        color: colors[i % colors.length].withValues(alpha: 0.7),
        strokeWidth: 1.5,
        dashArray: [5, 3],
      ));
    }
    
    return ExtraLinesData(verticalLines: lines);
  }
  
  Widget _buildMarkerLegend() {
    if (markerFrequencies == null || markerLabels == null) {
      return const SizedBox.shrink();
    }
    
    final colors = [
      AppTheme.statusGood,
      AppTheme.statusSatisfactory,
      AppTheme.statusUnsatisfactory,
      AppTheme.statusUnacceptable,
    ];
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: List.generate(
          math.min(markerFrequencies!.length, markerLabels!.length),
          (i) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 3,
                color: colors[i % colors.length],
              ),
              const SizedBox(width: 4),
              Text(
                '${markerLabels![i]}: ${markerFrequencies![i].toStringAsFixed(1)} Hz',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              color: AppTheme.textMuted,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'No spectrum data',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatAxisValue(double value) {
    if (value >= 1) return value.toStringAsFixed(2);
    if (value >= 0.1) return value.toStringAsFixed(3);
    return value.toStringAsFixed(4);
  }
}

/// Time waveform chart widget
class WaveformChart extends StatelessWidget {
  final List<double> data;
  final String title;
  final int sampleRate;
  
  const WaveformChart({
    super.key,
    required this.data,
    this.title = 'Time Waveform',
    this.sampleRate = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }
    
    final maxY = data.map((d) => d.abs()).reduce((a, b) => a > b ? a : b) * 1.1;
    final timeSpan = data.length / sampleRate; // seconds
    
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i / sampleRate * 1000, data[i])); // Convert to ms
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(timeSpan * 1000).toStringAsFixed(0)} ms',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: const Text(
                      'Time (ms)',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.chartGrid),
                ),
                minX: 0,
                maxX: timeSpan * 1000,
                minY: -maxY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: AppTheme.accentGreen,
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              color: AppTheme.textMuted,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'No waveform data',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trend chart for historical data
class TrendChart extends StatelessWidget {
  final List<double> values;
  final List<DateTime> timestamps;
  final String title;
  final String unit;
  final Map<String, double>? thresholds;
  
  const TrendChart({
    super.key,
    required this.values,
    required this.timestamps,
    this.title = 'Trend',
    this.unit = 'mm/s',
    this.thresholds,
  });
  
  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _buildEmptyChart();
    }
    
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;
    final minY = 0.0;
    
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppTheme.chartGrid,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= timestamps.length) {
                          return const SizedBox.shrink();
                        }
                        final date = timestamps[index];
                        return Text(
                          '${date.month}/${date.day}',
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppTheme.chartAxis,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                    axisNameWidget: Text(
                      unit,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppTheme.chartGrid),
                ),
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getStatusColor(spot.y),
                          strokeWidth: 2,
                          strokeColor: AppTheme.cardBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                extraLinesData: _buildThresholdLines(maxY),
              ),
            ),
          ),
          if (thresholds != null) _buildThresholdLegend(),
        ],
      ),
    );
  }
  
  ExtraLinesData _buildThresholdLines(double maxY) {
    if (thresholds == null) return ExtraLinesData(horizontalLines: []);
    
    final lines = <HorizontalLine>[];
    
    thresholds!.forEach((label, value) {
      if (value < maxY) {
        lines.add(HorizontalLine(
          y: value,
          color: _getThresholdColor(label),
          strokeWidth: 1,
          dashArray: [5, 3],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            labelResolver: (line) => label,
            style: TextStyle(
              color: _getThresholdColor(label),
              fontSize: 10,
            ),
          ),
        ));
      }
    });
    
    return ExtraLinesData(horizontalLines: lines);
  }
  
  Widget _buildThresholdLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        children: thresholds!.entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 3,
                color: _getThresholdColor(entry.key),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.key}: ${entry.value.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  Color _getStatusColor(double value) {
    if (thresholds == null) return AppTheme.accentBlue;
    
    final sortedThresholds = thresholds!.values.toList()..sort();
    if (sortedThresholds.isEmpty) return AppTheme.statusGood;
    
    if (value < sortedThresholds[0]) return AppTheme.statusGood;
    if (sortedThresholds.length > 1 && value < sortedThresholds[1]) {
      return AppTheme.statusSatisfactory;
    }
    if (sortedThresholds.length > 2 && value < sortedThresholds[2]) {
      return AppTheme.statusUnsatisfactory;
    }
    return AppTheme.statusUnacceptable;
  }
  
  Color _getThresholdColor(String label) {
    if (label.contains('A') || label.contains('Good')) return AppTheme.statusGood;
    if (label.contains('B') || label.contains('Satisfactory')) return AppTheme.statusSatisfactory;
    if (label.contains('C') || label.contains('Unsatisfactory')) return AppTheme.statusUnsatisfactory;
    return AppTheme.statusUnacceptable;
  }
  
  Widget _buildEmptyChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              color: AppTheme.textMuted,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'No trend data',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
