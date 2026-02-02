import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../constants/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/vibration_analyzer_service.dart';
import '../widgets/measurement_display.dart';
import '../widgets/spectrum_chart.dart';

/// Main measurement screen with real-time vibration analysis
/// Features:
/// - Wakelock to prevent screen sleep during measurement
/// - Large 150px measurement button for one-handed operation
/// - Strong haptic feedback for noisy environments
/// - Offline-capable operation
class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showSpectrum = true;
  bool _wakelockEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _enableWakelock();
  }
  
  @override
  void dispose() {
    _disableWakelock();
    _tabController.dispose();
    super.dispose();
  }
  
  /// Enable wakelock to keep screen on during measurement
  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      _wakelockEnabled = true;
    } catch (e) {
      // Wakelock may not be supported on web
      debugPrint('Wakelock not available: $e');
    }
  }
  
  /// Disable wakelock when leaving measurement screen
  Future<void> _disableWakelock() async {
    if (_wakelockEnabled) {
      try {
        await WakelockPlus.disable();
        _wakelockEnabled = false;
      } catch (e) {
        debugPrint('Error disabling wakelock: $e');
      }
    }
  }
  
  /// Provide strong haptic feedback for noisy factory environments
  void _strongHapticFeedback() {
    // Multiple haptic events for stronger feedback
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
  }
  
  /// Short vibration feedback - used for UI interactions
  void _lightHapticFeedback() {
    HapticFeedback.selectionClick();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Light haptic on page load for confirmation
    _lightHapticFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final result = provider.lastResult;
        final measurementState = provider.measurementState;
        final progress = provider.measurementProgress;
        
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: const Text('Vibration Measurement'),
            backgroundColor: AppTheme.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(context, provider),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Point Selection Header
                _buildPointSelector(provider),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Main measurement button
                        _buildMeasurementControl(
                          provider,
                          measurementState,
                          progress,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Results display
                        if (result != null) ...[
                          // ISO Zone Indicator
                          ISOZoneIndicator(
                            zone: result.isoZone,
                            machineClass: provider.selectedEquipment?.machineClass ?? 
                                provider.settings.defaultMachineClass,
                            velocityRms: result.velocityRms,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Main velocity display
                          MeasurementValueDisplay(
                            label: 'Velocity RMS',
                            value: result.velocityRms,
                            unit: 'mm/s',
                            valueColor: _getZoneColor(result.isoZone),
                            fontSize: 48,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Parameter grid
                          ParameterGrid(
                            accelRms: result.accelerationRms,
                            accelPeak: result.accelerationPeak,
                            velRms: result.velocityRms,
                            velPeak: result.velocityPeak,
                            dispRms: result.displacementRms,
                            dispPeak: result.displacementPeak,
                            crestFactor: result.crestFactor,
                            kurtosis: result.kurtosis,
                            displayUnit: provider.settings.displayUnit,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Chart toggle
                          _buildChartToggle(),
                          
                          const SizedBox(height: 8),
                          
                          // Charts
                          if (_showSpectrum)
                            SpectrumChart(
                              data: result.spectrum,
                              frequencyAxis: result.frequencyAxis,
                              title: 'FFT Spectrum',
                              maxFrequency: result.actualSampleRate / 2,
                            )
                          else
                            WaveformChart(
                              data: result.waveform,
                              title: 'Time Waveform',
                              sampleRate: provider.settings.sampleRate,
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Measurement info
                          _buildMeasurementInfo(result, provider),
                          
                          const SizedBox(height: 16),
                          
                          // Save button
                          _buildSaveButton(provider, result),
                        ] else ...[
                          // No result - show instruction
                          _buildInstructions(measurementState),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPointSelector(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.selectedEquipment?.name ?? 'No Equipment Selected',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (provider.selectedPoint != null)
                  Text(
                    '${provider.selectedLocation?.name ?? ''} > ${provider.selectedPoint!.name} (${provider.selectedPoint!.direction})',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showPointSelector(context, provider),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementControl(
    AppProvider provider,
    MeasurementState state,
    double progress,
  ) {
    final isMeasuring = state == MeasurementState.measuring;
    final isProcessing = state == MeasurementState.processing;
    
    return Column(
      children: [
        MeasurementButton(
          isMeasuring: isMeasuring,
          progress: progress,
          label: isMeasuring ? 'STOP' : (isProcessing ? 'PROCESSING' : 'MEASURE'),
          onPressed: isProcessing
              ? null
              : () async {
                  if (isMeasuring) {
                    await provider.stopMeasurement();
                    // Strong haptic feedback for measurement completion
                    _strongHapticFeedback();
                    // Success pattern: double vibration
                    Future.delayed(const Duration(milliseconds: 300), () {
                      HapticFeedback.heavyImpact();
                    });
                  } else {
                    provider.startMeasurement();
                    // Strong haptic for measurement start
                    _strongHapticFeedback();
                  }
                },
        ),
        const SizedBox(height: 12),
        if (isMeasuring)
          Text(
            'Collecting: ${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          )
        else if (isProcessing)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentBlue,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Processing FFT...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildChartToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showSpectrum = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _showSpectrum
                    ? AppTheme.accentBlue.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                border: Border.all(
                  color: _showSpectrum
                      ? AppTheme.accentBlue
                      : AppTheme.primaryLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: _showSpectrum
                        ? AppTheme.accentBlue
                        : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spectrum',
                    style: TextStyle(
                      color: _showSpectrum
                          ? AppTheme.accentBlue
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _showSpectrum = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_showSpectrum
                    ? AppTheme.accentGreen.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(8),
                ),
                border: Border.all(
                  color: !_showSpectrum
                      ? AppTheme.accentGreen
                      : AppTheme.primaryLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timeline,
                    color: !_showSpectrum
                        ? AppTheme.accentGreen
                        : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waveform',
                    style: TextStyle(
                      color: !_showSpectrum
                          ? AppTheme.accentGreen
                          : AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMeasurementInfo(MeasurementResult result, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Samples',
            result.sampleCount.toString(),
            Icons.data_array,
          ),
          _buildInfoItem(
            'Sample Rate',
            '${result.actualSampleRate.toStringAsFixed(0)} Hz',
            Icons.speed,
          ),
          _buildInfoItem(
            'FFT Size',
            provider.settings.fftSize.toString(),
            Icons.transform,
          ),
          _buildInfoItem(
            'Window',
            provider.settings.windowFunction.substring(0, 3),
            Icons.window,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSaveButton(AppProvider provider, MeasurementResult result) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.selectedPoint != null
            ? () => _showSaveDialog(context, provider)
            : null,
        icon: const Icon(Icons.save),
        label: const Text('Save Measurement'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGreen,
          foregroundColor: AppTheme.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructions(MeasurementState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            state == MeasurementState.idle
                ? Icons.touch_app
                : Icons.sensors,
            color: AppTheme.accentBlue,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            state == MeasurementState.idle
                ? 'Ready to Measure'
                : 'Measuring...',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state == MeasurementState.idle
                ? 'Press the button above to start vibration measurement.\nHold your device firmly against the measurement point.'
                : 'Keep the device steady on the measurement point.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (state == MeasurementState.idle) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: _InstructionStep(
                  number: '1',
                  text: 'Select point',
                  icon: Icons.location_on,
                )),
                Expanded(child: _InstructionStep(
                  number: '2',
                  text: 'Place device',
                  icon: Icons.smartphone,
                )),
                Expanded(child: _InstructionStep(
                  number: '3',
                  text: 'Measure',
                  icon: Icons.play_arrow,
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getZoneColor(String zone) {
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
        return AppTheme.textPrimary;
    }
  }
  
  void _showPointSelector(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PointSelectorSheet(provider: provider),
    );
  }
  
  void _showSettingsDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(provider: provider),
    );
  }
  
  void _showSaveDialog(BuildContext context, AppProvider provider) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('Save Measurement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save to: ${provider.selectedPoint?.name ?? "No point selected"}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any observations...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.saveMeasurement(notes: notesController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Measurement saved successfully'),
                    backgroundColor: AppTheme.statusGood,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;
  final IconData icon;
  
  const _InstructionStep({
    required this.number,
    required this.text,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: AppTheme.accentBlue, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PointSelectorSheet extends StatelessWidget {
  final AppProvider provider;
  
  const _PointSelectorSheet({required this.provider});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Measurement Point',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (provider.equipment.isEmpty)
            const Center(
              child: Text(
                'No equipment configured',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: provider.equipment.length,
                itemBuilder: (context, index) {
                  final eq = provider.equipment[index];
                  return ExpansionTile(
                    title: Text(
                      eq.name,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      eq.machineClass,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    leading: const Icon(Icons.precision_manufacturing, color: AppTheme.accentBlue),
                    children: _buildLocationTiles(context, eq.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildLocationTiles(BuildContext context, String equipmentId) {
    final locations = provider.equipment
        .where((e) => e.id == equipmentId)
        .isNotEmpty
        ? provider.equipment.firstWhere((e) => e.id == equipmentId)
        : null;
    
    if (locations == null) return [];
    
    // Get locations for this equipment
    final locs = provider.locations.where((l) => l.equipmentId == equipmentId).toList();
    
    if (locs.isEmpty) {
      provider.selectEquipment(locations);
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No locations configured',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ];
    }
    
    return locs.map((loc) {
      final points = provider.points.where((p) => p.locationId == loc.id).toList();
      
      return ExpansionTile(
        title: Text(
          loc.name,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        leading: const Icon(Icons.location_on, color: AppTheme.textMuted, size: 20),
        children: points.map((point) {
          return ListTile(
            leading: const Icon(Icons.sensors, color: AppTheme.accentGreen, size: 20),
            title: Text(
              point.name,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              point.direction,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            onTap: () {
              provider.selectEquipment(locations);
              provider.selectLocation(loc);
              provider.selectPoint(point);
              Navigator.pop(context);
            },
          );
        }).toList(),
      );
    }).toList();
  }
}

class _SettingsSheet extends StatefulWidget {
  final AppProvider provider;
  
  const _SettingsSheet({required this.provider});
  
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int _fftSize;
  late String _windowFunction;
  late String _averageType;
  late int _averageCount;
  late String _displayUnit;
  
  @override
  void initState() {
    super.initState();
    final settings = widget.provider.settings;
    _fftSize = settings.fftSize;
    _windowFunction = settings.windowFunction;
    _averageType = settings.averageType;
    _averageCount = settings.averageCount;
    _displayUnit = settings.displayUnit;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Measurement Settings',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          // FFT Size
          _buildDropdown(
            'FFT Size',
            _fftSize.toString(),
            ['1024', '2048', '4096'],
            (value) => setState(() => _fftSize = int.parse(value!)),
          ),
          
          // Window Function
          _buildDropdown(
            'Window Function',
            _windowFunction,
            ['Hanning', 'Hamming', 'Flat-Top', 'Rectangular'],
            (value) => setState(() => _windowFunction = value!),
          ),
          
          // Average Type
          _buildDropdown(
            'Averaging',
            _averageType,
            ['Linear', 'Exponential'],
            (value) => setState(() => _averageType = value!),
          ),
          
          // Average Count
          _buildDropdown(
            'Average Count',
            _averageCount.toString(),
            ['1', '2', '4', '8', '16', '32'],
            (value) => setState(() => _averageCount = int.parse(value!)),
          ),
          
          // Display Unit
          _buildDropdown(
            'Acceleration Unit',
            _displayUnit,
            ['g', 'm/s²'],
            (value) => setState(() => _displayUnit = value!),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final newSettings = widget.provider.settings.copyWith(
                  fftSize: _fftSize,
                  windowFunction: _windowFunction,
                  averageType: _averageType,
                  averageCount: _averageCount,
                  displayUnit: _displayUnit,
                );
                widget.provider.updateSettings(newSettings);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              dropdownColor: AppTheme.surfaceLight,
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
