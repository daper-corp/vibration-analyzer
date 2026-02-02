import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

/// Bearing fault frequency calculator screen
class BearingCalculatorScreen extends StatefulWidget {
  const BearingCalculatorScreen({super.key});

  @override
  State<BearingCalculatorScreen> createState() => _BearingCalculatorScreenState();
}

class _BearingCalculatorScreenState extends State<BearingCalculatorScreen> {
  // Input controllers
  final _rpmController = TextEditingController(text: '1480');
  final _rollingElementsController = TextEditingController();
  final _pitchDiameterController = TextEditingController();
  final _elementDiameterController = TextEditingController();
  final _contactAngleController = TextEditingController(text: '0');
  
  // Selected bearing from database
  BearingGeometry? _selectedBearing;
  
  // Calculated frequencies
  double? _shaftFreq;
  double? _bpfo;
  double? _bpfi;
  double? _bsf;
  double? _ftf;
  
  @override
  void dispose() {
    _rpmController.dispose();
    _rollingElementsController.dispose();
    _pitchDiameterController.dispose();
    _elementDiameterController.dispose();
    _contactAngleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Bearing Calculator'),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bearing selection
            _buildBearingSelector(),
            
            const SizedBox(height: 24),
            
            // RPM input
            _buildRpmInput(),
            
            const SizedBox(height: 24),
            
            // Manual input (if no bearing selected)
            if (_selectedBearing == null) ...[
              _buildManualInput(),
              const SizedBox(height: 24),
            ],
            
            // Calculate button
            _buildCalculateButton(),
            
            const SizedBox(height: 24),
            
            // Results
            if (_bpfo != null) _buildResults(),
            
            const SizedBox(height: 24),
            
            // Fault pattern hints
            _buildFaultPatternHints(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBearingSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                const Text(
                  'Bearing Selection',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BearingGeometry>(
              decoration: const InputDecoration(
                labelText: 'Select from database',
                hintText: 'Choose a bearing or enter manually',
              ),
              dropdownColor: AppTheme.surfaceLight,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Manual Entry'),
                ),
                ...BearingDatabase.commonBearings.map((b) {
                  return DropdownMenuItem(
                    value: b,
                    child: Text(b.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBearing = value;
                  if (value != null) {
                    _rollingElementsController.text = value.rollingElements.toString();
                    _pitchDiameterController.text = value.pitchDiameter.toString();
                    _elementDiameterController.text = value.elementDiameter.toString();
                    _contactAngleController.text = value.contactAngle.toString();
                  }
                });
              },
            ),
            if (_selectedBearing != null) ...[
              const SizedBox(height: 16),
              _buildBearingSpecs(_selectedBearing!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildBearingSpecs(BearingGeometry bearing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpecItem('Elements', bearing.rollingElements.toString()),
          _buildSpecItem('Pitch Ø', '${bearing.pitchDiameter} mm'),
          _buildSpecItem('Ball Ø', '${bearing.elementDiameter} mm'),
          _buildSpecItem('Angle', '${bearing.contactAngle}°'),
        ],
      ),
    );
  }
  
  Widget _buildSpecItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.accentCyan,
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
  
  Widget _buildRpmInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: AppTheme.accentGreen),
                const SizedBox(width: 8),
                const Text(
                  'Shaft Speed',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rpmController,
              decoration: const InputDecoration(
                labelText: 'RPM',
                suffixText: 'rev/min',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildManualInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                const Text(
                  'Bearing Geometry',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rollingElementsController,
                    decoration: const InputDecoration(
                      labelText: 'Rolling Elements',
                      hintText: 'e.g., 9',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _contactAngleController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Angle',
                      suffixText: '°',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pitchDiameterController,
                    decoration: const InputDecoration(
                      labelText: 'Pitch Diameter',
                      suffixText: 'mm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _elementDiameterController,
                    decoration: const InputDecoration(
                      labelText: 'Element Diameter',
                      suffixText: 'mm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calculateFrequencies,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate Frequencies'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
  
  void _calculateFrequencies() {
    final rpm = double.tryParse(_rpmController.text);
    final n = int.tryParse(_rollingElementsController.text);
    final pd = double.tryParse(_pitchDiameterController.text);
    final ed = double.tryParse(_elementDiameterController.text);
    final ca = double.tryParse(_contactAngleController.text) ?? 0;
    
    if (rpm == null || rpm <= 0) {
      _showError('Please enter a valid RPM');
      return;
    }
    
    BearingGeometry bearing;
    
    if (_selectedBearing != null) {
      bearing = _selectedBearing!;
    } else {
      if (n == null || pd == null || ed == null) {
        _showError('Please enter all bearing geometry values');
        return;
      }
      bearing = BearingGeometry(
        name: 'Custom',
        rollingElements: n,
        pitchDiameter: pd,
        elementDiameter: ed,
        contactAngle: ca,
      );
    }
    
    setState(() {
      _shaftFreq = rpm / 60;
      _bpfo = bearing.calculateBPFO(rpm);
      _bpfi = bearing.calculateBPFI(rpm);
      _bsf = bearing.calculateBSF(rpm);
      _ftf = bearing.calculateFTF(rpm);
    });
    
    HapticFeedback.mediumImpact();
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusUnacceptable,
      ),
    );
  }
  
  Widget _buildResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calculated Frequencies',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  color: AppTheme.accentBlue,
                  onPressed: _copyResults,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Shaft frequency
            _buildFrequencyRow(
              'Shaft (1x)',
              _shaftFreq!,
              AppTheme.textPrimary,
              'Basic running speed',
            ),
            
            const Divider(color: AppTheme.primaryLight, height: 24),
            
            // BPFO
            _buildFrequencyRow(
              'BPFO',
              _bpfo!,
              AppTheme.statusUnacceptable,
              'Ball Pass Frequency Outer Race',
            ),
            
            // BPFI
            _buildFrequencyRow(
              'BPFI',
              _bpfi!,
              AppTheme.statusUnsatisfactory,
              'Ball Pass Frequency Inner Race',
            ),
            
            // BSF
            _buildFrequencyRow(
              'BSF',
              _bsf!,
              AppTheme.accentBlue,
              'Ball Spin Frequency',
            ),
            
            // FTF
            _buildFrequencyRow(
              'FTF',
              _ftf!,
              AppTheme.accentGreen,
              'Fundamental Train Frequency (Cage)',
            ),
            
            const SizedBox(height: 16),
            
            // Harmonics table
            _buildHarmonicsTable(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFrequencyRow(String label, double freq, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${freq.toStringAsFixed(2)} Hz',
              style: const TextStyle(
                color: AppTheme.valueHighlight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHarmonicsTable() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harmonics (2x, 3x)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader(''),
                  _buildTableHeader('1x'),
                  _buildTableHeader('2x'),
                  _buildTableHeader('3x'),
                ],
              ),
              _buildTableRow('BPFO', _bpfo!),
              _buildTableRow('BPFI', _bpfi!),
              _buildTableRow('BSF', _bsf!),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  TableRow _buildTableRow(String label, double baseFreq) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ),
        _buildTableCell(baseFreq),
        _buildTableCell(baseFreq * 2),
        _buildTableCell(baseFreq * 3),
      ],
    );
  }
  
  Widget _buildTableCell(double freq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        freq.toStringAsFixed(1),
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  void _copyResults() {
    if (_bpfo == null) return;
    
    final text = '''
Bearing Fault Frequencies
RPM: ${_rpmController.text}
Shaft: ${_shaftFreq!.toStringAsFixed(2)} Hz
BPFO: ${_bpfo!.toStringAsFixed(2)} Hz
BPFI: ${_bpfi!.toStringAsFixed(2)} Hz
BSF: ${_bsf!.toStringAsFixed(2)} Hz
FTF: ${_ftf!.toStringAsFixed(2)} Hz
''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: AppTheme.statusGood,
      ),
    );
  }
  
  Widget _buildFaultPatternHints() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.accentBlue),
                const SizedBox(width: 8),
                const Text(
                  'Diagnostic Hints',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHintItem(
              'Unbalance',
              '1x shaft frequency, radial direction dominant',
              Icons.sync_problem,
              AppTheme.statusSatisfactory,
            ),
            _buildHintItem(
              'Misalignment',
              '2x shaft frequency, axial vibration present',
              Icons.compare_arrows,
              AppTheme.statusUnsatisfactory,
            ),
            _buildHintItem(
              'Looseness',
              'Multiple harmonics (0.5x, 1x, 2x, 3x...)',
              Icons.link_off,
              AppTheme.statusUnacceptable,
            ),
            _buildHintItem(
              'Bearing Outer Race',
              'BPFO and harmonics, non-rotating',
              Icons.circle_outlined,
              AppTheme.statusUnacceptable,
            ),
            _buildHintItem(
              'Bearing Inner Race',
              'BPFI with sidebands at 1x',
              Icons.radio_button_checked,
              AppTheme.statusUnacceptable,
            ),
            _buildHintItem(
              'Rolling Element',
              '2x BSF, may have sidebands at FTF',
              Icons.sports_baseball,
              AppTheme.accentBlue,
            ),
            _buildHintItem(
              'Cage Defect',
              'FTF and harmonics, low frequency',
              Icons.all_inclusive,
              AppTheme.accentGreen,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHintItem(String fault, String pattern, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fault,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  pattern,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
