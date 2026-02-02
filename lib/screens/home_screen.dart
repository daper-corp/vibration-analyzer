import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/app_provider.dart';
import 'measurement_screen.dart';
import 'equipment_screen.dart';
import 'history_screen.dart';
import 'bearing_calculator_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  void navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }
  
  final List<Widget> _screens = [
    const _DashboardTab(),
    const MeasurementScreen(),
    const EquipmentScreen(),
    const HistoryScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.primaryDark,
          selectedItemColor: AppTheme.accentBlue,
          unselectedItemColor: AppTheme.textMuted,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors),
              label: 'Measure',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.precision_manufacturing),
              label: 'Equipment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.vibration,
                    color: AppTheme.primaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vibration Analyzer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Predictive Maintenance',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.calculate),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BearingCalculatorScreen(),
                    ),
                  );
                },
                tooltip: 'Bearing Calculator',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick measurement card
                _buildQuickMeasureCard(context),
                
                const SizedBox(height: 24),
                
                // Equipment overview
                _buildEquipmentOverview(context, provider),
                
                const SizedBox(height: 24),
                
                // Recent measurements
                _buildRecentMeasurements(context, provider),
                
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(context),
                
                const SizedBox(height: 24),
                
                // ISO 10816 reference
                _buildISOReference(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQuickMeasureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start Measurement',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place device on measurement point and tap to start',
                  style: TextStyle(
                    color: AppTheme.primaryDark.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.navigateToTab(1);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: AppTheme.accentGreen,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEquipmentOverview(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Equipment',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?.navigateToTab(2);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.equipment.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.add_box, color: AppTheme.textMuted, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'No equipment added yet',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.equipment.length,
              itemBuilder: (context, index) {
                final eq = provider.equipment[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
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
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eq.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${eq.machineClass} • ${eq.nominalRpm?.toStringAsFixed(0) ?? "N/A"} RPM',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildRecentMeasurements(BuildContext context, AppProvider provider) {
    final recent = provider.getRecentMeasurements(limit: 5);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Measurements',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?.navigateToTab(3);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.timeline, color: AppTheme.textMuted, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'No measurements yet',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.take(3).map((m) => _buildMeasurementItem(m)),
      ],
    );
  }
  
  Widget _buildMeasurementItem(measurement) {
    Color zoneColor;
    switch (measurement.isoZone) {
      case 'A':
        zoneColor = AppTheme.statusGood;
        break;
      case 'B':
        zoneColor = AppTheme.statusSatisfactory;
        break;
      case 'C':
        zoneColor = AppTheme.statusUnsatisfactory;
        break;
      case 'D':
        zoneColor = AppTheme.statusUnacceptable;
        break;
      default:
        zoneColor = AppTheme.textMuted;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                measurement.isoZone,
                style: TextStyle(
                  color: zoneColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${measurement.velocityRms.toStringAsFixed(2)} mm/s RMS',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimestamp(measurement.timestamp),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${timestamp.month}/${timestamp.day}';
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Bearing\nCalculator',
                Icons.calculate,
                AppTheme.accentBlue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BearingCalculatorScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'ISO 10816\nReference',
                Icons.menu_book,
                AppTheme.accentGreen,
                () => _showISODialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Export\nData',
                Icons.file_download,
                AppTheme.accentCyan,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export feature coming soon'),
                      backgroundColor: AppTheme.accentBlue,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildISOReference() {
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
            children: [
              const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ISO 10816-1 Quick Reference',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildZoneIndicator('A', 'Good', AppTheme.statusGood),
              _buildZoneIndicator('B', 'OK', AppTheme.statusSatisfactory),
              _buildZoneIndicator('C', 'Alert', AppTheme.statusUnsatisfactory),
              _buildZoneIndicator('D', 'Danger', AppTheme.statusUnacceptable),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildZoneIndicator(String zone, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              zone,
              style: TextStyle(
                color: zone == 'D' ? Colors.white : AppTheme.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
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
  
  void _showISODialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('ISO 10816-1 Vibration Severity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Velocity RMS (mm/s) Limits by Machine Class:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildISOTable(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildISOTable() {
    return Table(
      border: TableBorder.all(color: AppTheme.primaryLight, width: 0.5),
      children: const [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.surfaceLight),
          children: [
            _TableCell('Zone', isHeader: true),
            _TableCell('Class I', isHeader: true),
            _TableCell('Class II', isHeader: true),
            _TableCell('Class III', isHeader: true),
            _TableCell('Class IV', isHeader: true),
          ],
        ),
        TableRow(children: [
          _TableCell('A', color: AppTheme.statusGood),
          _TableCell('< 0.71'),
          _TableCell('< 1.12'),
          _TableCell('< 1.8'),
          _TableCell('< 2.8'),
        ]),
        TableRow(children: [
          _TableCell('B', color: AppTheme.statusSatisfactory),
          _TableCell('0.71-1.8'),
          _TableCell('1.12-2.8'),
          _TableCell('1.8-4.5'),
          _TableCell('2.8-7.1'),
        ]),
        TableRow(children: [
          _TableCell('C', color: AppTheme.statusUnsatisfactory),
          _TableCell('1.8-4.5'),
          _TableCell('2.8-7.1'),
          _TableCell('4.5-11.2'),
          _TableCell('7.1-18'),
        ]),
        TableRow(children: [
          _TableCell('D', color: AppTheme.statusUnacceptable),
          _TableCell('> 4.5'),
          _TableCell('> 7.1'),
          _TableCell('> 11.2'),
          _TableCell('> 18'),
        ]),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final Color? color;
  
  const _TableCell(this.text, {this.isHeader = false, this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? (isHeader ? AppTheme.textPrimary : AppTheme.textSecondary),
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
