import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/measurement.dart';
import '../providers/app_provider.dart';
import '../widgets/spectrum_chart.dart';

/// Measurement history and trend analysis screen
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dateFormat = DateFormat('MM/dd HH:mm');
  String _filterType = 'all'; // 'all', 'today', 'week', 'month'
  String _sortBy = 'date'; // 'date', 'velocity', 'zone'
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final measurements = _getFilteredMeasurements(provider);
        
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: const Text('History'),
            backgroundColor: AppTheme.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context),
              ),
            ],
          ),
          body: measurements.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary stats
                    _buildSummaryStats(measurements),
                    
                    // Filter chips
                    _buildFilterChips(),
                    
                    // Measurement list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: measurements.length,
                        itemBuilder: (context, index) {
                          return _MeasurementCard(
                            measurement: measurements[index],
                            dateFormat: _dateFormat,
                            onTap: () => _showMeasurementDetail(
                              context,
                              measurements[index],
                              provider,
                            ),
                            onDelete: () => _confirmDelete(
                              context,
                              measurements[index],
                              provider,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
  
  List<Measurement> _getFilteredMeasurements(AppProvider provider) {
    var measurements = provider.getRecentMeasurements(limit: 100);
    
    // Apply date filter
    final now = DateTime.now();
    switch (_filterType) {
      case 'today':
        measurements = measurements.where((m) =>
          m.timestamp.day == now.day &&
          m.timestamp.month == now.month &&
          m.timestamp.year == now.year
        ).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        measurements = measurements.where((m) => m.timestamp.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        measurements = measurements.where((m) => m.timestamp.isAfter(monthAgo)).toList();
        break;
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'velocity':
        measurements.sort((a, b) => b.velocityRms.compareTo(a.velocityRms));
        break;
      case 'zone':
        final zoneOrder = {'D': 0, 'C': 1, 'B': 2, 'A': 3};
        measurements.sort((a, b) => 
          (zoneOrder[a.isoZone] ?? 4).compareTo(zoneOrder[b.isoZone] ?? 4));
        break;
      default:
        measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    return measurements;
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              color: AppTheme.textMuted,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Measurements',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start taking measurements to build your history and trend data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryStats(List<Measurement> measurements) {
    if (measurements.isEmpty) return const SizedBox.shrink();
    
    final velocities = measurements.map((m) => m.velocityRms).toList();
    final avgVelocity = velocities.reduce((a, b) => a + b) / velocities.length;
    final maxVelocity = velocities.reduce((a, b) => a > b ? a : b);
    
    // Zone distribution
    int zoneA = 0, zoneB = 0, zoneC = 0, zoneD = 0;
    for (final m in measurements) {
      switch (m.isoZone) {
        case 'A': zoneA++; break;
        case 'B': zoneB++; break;
        case 'C': zoneC++; break;
        case 'D': zoneD++; break;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryLight, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              measurements.length.toString(),
              Icons.format_list_numbered,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Avg Vel',
              '${avgVelocity.toStringAsFixed(2)} mm/s',
              Icons.speed,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Max Vel',
              '${maxVelocity.toStringAsFixed(2)} mm/s',
              Icons.trending_up,
            ),
          ),
          Expanded(
            child: _buildZoneDistribution(zoneA, zoneB, zoneC, zoneD, measurements.length),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
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
  
  Widget _buildZoneDistribution(int a, int b, int c, int d, int total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneDot('A', a, total, AppTheme.statusGood),
            const SizedBox(width: 4),
            _buildZoneDot('B', b, total, AppTheme.statusSatisfactory),
            const SizedBox(width: 4),
            _buildZoneDot('C', c, total, AppTheme.statusUnsatisfactory),
            const SizedBox(width: 4),
            _buildZoneDot('D', d, total, AppTheme.statusUnacceptable),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Zone Dist.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildZoneDot(String zone, int count, int total, Color color) {
    final size = 8.0 + (count / total * 12).clamp(0, 12);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: count > 0 ? color : color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('All', 'all'),
          const SizedBox(width: 8),
          _buildChip('Today', 'today'),
          const SizedBox(width: 8),
          _buildChip('Week', 'week'),
          const SizedBox(width: 8),
          _buildChip('Month', 'month'),
        ],
      ),
    );
  }
  
  Widget _buildChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : AppTheme.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildSortOption('Date (Newest)', 'date'),
            _buildSortOption('Velocity (Highest)', 'velocity'),
            _buildSortOption('ISO Zone (Worst)', 'zone'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
        ),
      ),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }
  
  void _showMeasurementDetail(
    BuildContext context,
    Measurement measurement,
    AppProvider provider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MeasurementDetailScreen(
          measurement: measurement,
          provider: provider,
        ),
      ),
    );
  }
  
  void _confirmDelete(
    BuildContext context,
    Measurement measurement,
    AppProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('Delete Measurement'),
        content: Text(
          'Delete measurement from ${_dateFormat.format(measurement.timestamp)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteMeasurement(measurement.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusUnacceptable,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const _MeasurementCard({
    required this.measurement,
    required this.dateFormat,
    required this.onTap,
    required this.onDelete,
  });
  
  Color get zoneColor {
    switch (measurement.isoZone) {
      case 'A': return AppTheme.statusGood;
      case 'B': return AppTheme.statusSatisfactory;
      case 'C': return AppTheme.statusUnsatisfactory;
      case 'D': return AppTheme.statusUnacceptable;
      default: return AppTheme.textMuted;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Zone indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: zoneColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    measurement.isoZone,
                    style: TextStyle(
                      color: zoneColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(measurement.timestamp),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniStat('Vel', '${measurement.velocityRms.toStringAsFixed(2)} mm/s'),
                        const SizedBox(width: 12),
                        _buildMiniStat('CF', measurement.crestFactor.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MeasurementDetailScreen extends StatelessWidget {
  final Measurement measurement;
  final AppProvider provider;
  
  const _MeasurementDetailScreen({
    required this.measurement,
    required this.provider,
  });
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Measurement Detail'),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareMeasurement(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with timestamp and zone
            _buildHeader(dateFormat),
            
            const SizedBox(height: 24),
            
            // Parameters
            _buildParametersCard(),
            
            const SizedBox(height: 16),
            
            // Spectrum chart
            SpectrumChart(
              data: measurement.spectrumData,
              frequencyAxis: List.generate(
                measurement.spectrumData.length,
                (i) => i * (measurement.sampleRate / measurement.fftSize),
              ),
              title: 'FFT Spectrum',
            ),
            
            const SizedBox(height: 16),
            
            // Waveform chart
            WaveformChart(
              data: measurement.waveformData,
              title: 'Time Waveform',
              sampleRate: measurement.sampleRate,
            ),
            
            const SizedBox(height: 16),
            
            // Measurement settings
            _buildSettingsCard(),
            
            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(DateFormat dateFormat) {
    Color zoneColor;
    String zoneLabel;
    
    switch (measurement.isoZone) {
      case 'A':
        zoneColor = AppTheme.statusGood;
        zoneLabel = 'Good';
        break;
      case 'B':
        zoneColor = AppTheme.statusSatisfactory;
        zoneLabel = 'Satisfactory';
        break;
      case 'C':
        zoneColor = AppTheme.statusUnsatisfactory;
        zoneLabel = 'Unsatisfactory';
        break;
      case 'D':
        zoneColor = AppTheme.statusUnacceptable;
        zoneLabel = 'Unacceptable';
        break;
      default:
        zoneColor = AppTheme.textMuted;
        zoneLabel = 'Unknown';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: zoneColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  measurement.isoZone,
                  style: TextStyle(
                    color: measurement.isoZone == 'D' ? Colors.white : AppTheme.primaryDark,
                    fontSize: 32,
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
                    dateFormat.format(measurement.timestamp),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: zoneColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Zone $zoneLabel',
                          style: TextStyle(
                            color: zoneColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        measurement.machineClass,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vibration Parameters',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildParamRow('Acceleration RMS', '${measurement.accelerationRms.toStringAsFixed(4)} m/s²'),
            _buildParamRow('Acceleration Peak', '${measurement.accelerationPeak.toStringAsFixed(4)} m/s²'),
            const Divider(color: AppTheme.primaryLight, height: 24),
            _buildParamRow('Velocity RMS', '${measurement.velocityRms.toStringAsFixed(3)} mm/s', highlight: true),
            _buildParamRow('Velocity Peak', '${measurement.velocityPeak.toStringAsFixed(3)} mm/s'),
            const Divider(color: AppTheme.primaryLight, height: 24),
            _buildParamRow('Displacement RMS', '${measurement.displacementRms.toStringAsFixed(2)} μm'),
            _buildParamRow('Displacement Peak', '${measurement.displacementPeak.toStringAsFixed(2)} μm'),
            const Divider(color: AppTheme.primaryLight, height: 24),
            _buildParamRow('Crest Factor', measurement.crestFactor.toStringAsFixed(2)),
            _buildParamRow('Kurtosis', measurement.kurtosis.toStringAsFixed(2)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParamRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.valueHighlight : AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Measurement Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildSettingChip('FFT: ${measurement.fftSize}'),
                _buildSettingChip(measurement.windowFunction),
                _buildSettingChip('${measurement.sampleRate} Hz'),
                if (measurement.rpm != null)
                  _buildSettingChip('${measurement.rpm!.toStringAsFixed(0)} RPM'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: AppTheme.accentBlue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              measurement.notes!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _shareMeasurement(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }
}
