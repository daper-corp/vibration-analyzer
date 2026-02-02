import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

/// Large measurement value display widget
class MeasurementValueDisplay extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color? valueColor;
  final double? fontSize;
  final bool showTrend;
  final double? previousValue;
  
  const MeasurementValueDisplay({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.fontSize,
    this.showTrend = false,
    this.previousValue,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showTrend && previousValue != null) _buildTrendIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  color: valueColor ?? AppTheme.valueHighlight,
                  fontSize: fontSize ?? 36,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  color: AppTheme.unitLabel,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendIndicator() {
    if (previousValue == null) return const SizedBox.shrink();
    
    final change = value - previousValue!;
    final percentChange = previousValue! != 0 ? (change / previousValue! * 100) : 0;
    
    IconData icon;
    Color color;
    
    if (change > 0) {
      icon = Icons.trending_up;
      color = AppTheme.statusUnacceptable;
    } else if (change < 0) {
      icon = Icons.trending_down;
      color = AppTheme.statusGood;
    } else {
      icon = Icons.trending_flat;
      color = AppTheme.textSecondary;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '${percentChange.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
  
  String _formatValue(double val) {
    if (val.abs() >= 100) {
      return val.toStringAsFixed(1);
    } else if (val.abs() >= 10) {
      return val.toStringAsFixed(2);
    } else if (val.abs() >= 1) {
      return val.toStringAsFixed(3);
    } else {
      return val.toStringAsFixed(4);
    }
  }
}

/// ISO 10816 Zone indicator widget
class ISOZoneIndicator extends StatelessWidget {
  final String zone;
  final String machineClass;
  final double velocityRms;
  final bool showDetails;
  
  const ISOZoneIndicator({
    super.key,
    required this.zone,
    required this.machineClass,
    required this.velocityRms,
    this.showDetails = true,
  });
  
  Color get zoneColor {
    switch (zone) {
      case 'A':
        return AppTheme.statusGood;
      case 'B':
        return AppTheme.statusSatisfactory;
      case 'C':
        return AppTheme.statusUnsatisfactory;
      case 'D':
        return AppTheme.statusUnacceptable;
      default:
        return AppTheme.textMuted;
    }
  }
  
  String get zoneLabel {
    switch (zone) {
      case 'A':
        return 'Good';
      case 'B':
        return 'Satisfactory';
      case 'C':
        return 'Unsatisfactory';
      case 'D':
        return 'Unacceptable';
      default:
        return 'Unknown';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            zoneColor.withValues(alpha: 0.2),
            zoneColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zoneColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ISO 10816',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  machineClass,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: zoneColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: zoneColor.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    zone,
                    style: TextStyle(
                      color: zone == 'D' ? Colors.white : AppTheme.primaryDark,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoneLabel,
                      style: TextStyle(
                        color: zoneColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (showDetails)
                      Text(
                        AppConstants.zoneDescriptions[zone] ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 12),
            _buildZoneBar(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildZoneBar() {
    // Get limits for current machine class
    Map<String, List<double>> limits;
    switch (machineClass) {
      case 'Class I':
        limits = AppConstants.isoClass1Limits;
        break;
      case 'Class III':
        limits = AppConstants.isoClass3Limits;
        break;
      case 'Class IV':
        limits = AppConstants.isoClass4Limits;
        break;
      default:
        limits = AppConstants.isoClass2Limits;
    }
    
    final maxValue = limits['C']![1];
    
    return Column(
      children: [
        // Background zones
        Row(
          children: [
            Expanded(
              flex: ((limits['A']![1] / maxValue) * 100).round(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.statusGood.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
            Expanded(
              flex: (((limits['B']![1] - limits['A']![1]) / maxValue) * 100).round(),
              child: Container(
                height: 8,
                color: AppTheme.statusSatisfactory.withValues(alpha: 0.3),
              ),
            ),
            Expanded(
              flex: (((limits['C']![1] - limits['B']![1]) / maxValue) * 100).round(),
              child: Container(
                height: 8,
                color: AppTheme.statusUnsatisfactory.withValues(alpha: 0.3),
              ),
            ),
            Expanded(
              flex: 20,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.statusUnacceptable.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text('${velocityRms.toStringAsFixed(2)} mm/s', 
              style: TextStyle(color: zoneColor, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('${maxValue.toStringAsFixed(1)}+', 
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

/// Large measurement button for field use (150px for one-handed operation)
class MeasurementButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isMeasuring;
  final double progress;
  final String? label;
  
  const MeasurementButton({
    super.key,
    this.onPressed,
    this.isMeasuring = false,
    this.progress = 0,
    this.label,
  });

  @override
  State<MeasurementButton> createState() => _MeasurementButtonState();
}

class _MeasurementButtonState extends State<MeasurementButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Button size: 150px for easy one-handed operation in field
    const buttonSize = 150.0;
    const progressSize = 140.0;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isMeasuring 
            ? 1.0 // No pulse when measuring
            : (_isPressed ? 0.95 : _pulseAnimation.value);
            
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onPressed,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isMeasuring
                    ? const LinearGradient(
                        colors: [AppTheme.statusUnacceptable, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppTheme.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isMeasuring 
                        ? AppTheme.statusUnacceptable 
                        : AppTheme.accentBlue)
                        .withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isMeasuring)
                    SizedBox(
                      width: progressSize,
                      height: progressSize,
                      child: CircularProgressIndicator(
                        value: widget.progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isMeasuring ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: AppTheme.primaryDark,
                        size: 56,
                      ),
                      if (widget.label != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.label!,
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Parameter grid display
class ParameterGrid extends StatelessWidget {
  final double accelRms;
  final double accelPeak;
  final double velRms;
  final double velPeak;
  final double dispRms;
  final double dispPeak;
  final double crestFactor;
  final double kurtosis;
  final String displayUnit; // 'm/s²' or 'g'
  
  const ParameterGrid({
    super.key,
    required this.accelRms,
    required this.accelPeak,
    required this.velRms,
    required this.velPeak,
    required this.dispRms,
    required this.dispPeak,
    required this.crestFactor,
    required this.kurtosis,
    this.displayUnit = 'g',
  });
  
  @override
  Widget build(BuildContext context) {
    final accelFactor = displayUnit == 'g' ? 1 / AppConstants.gravity : 1.0;
    final accelUnit = displayUnit == 'g' ? 'g' : 'm/s²';
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildParameterCard(
                'Acceleration',
                accelRms * accelFactor,
                accelPeak * accelFactor,
                accelUnit,
                AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParameterCard(
                'Velocity',
                velRms,
                velPeak,
                'mm/s',
                AppTheme.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildParameterCard(
                'Displacement',
                dispRms,
                dispPeak,
                'μm',
                AppTheme.accentCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFactorCard(),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildParameterCard(String label, double rms, double peak, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RMS', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    _formatValue(rms),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Peak', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    _formatValue(peak),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFactorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnostics',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Crest', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    crestFactor.toStringAsFixed(2),
                    style: TextStyle(
                      color: _getCrestFactorColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Kurtosis', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(
                    kurtosis.toStringAsFixed(2),
                    style: TextStyle(
                      color: _getKurtosisColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getCrestFactorColor() {
    if (crestFactor < 3) return AppTheme.statusGood;
    if (crestFactor < 4) return AppTheme.statusSatisfactory;
    if (crestFactor < 5) return AppTheme.statusUnsatisfactory;
    return AppTheme.statusUnacceptable;
  }
  
  Color _getKurtosisColor() {
    if (kurtosis < 3) return AppTheme.statusGood;
    if (kurtosis < 5) return AppTheme.statusSatisfactory;
    if (kurtosis < 7) return AppTheme.statusUnsatisfactory;
    return AppTheme.statusUnacceptable;
  }
  
  String _formatValue(double val) {
    if (val.abs() >= 100) return val.toStringAsFixed(1);
    if (val.abs() >= 10) return val.toStringAsFixed(2);
    if (val.abs() >= 1) return val.toStringAsFixed(3);
    return val.toStringAsFixed(4);
  }
}
