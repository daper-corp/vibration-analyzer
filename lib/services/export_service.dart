import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/measurement.dart';

/// Export service for CSV and PDF reports
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();
  
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final _dateFormatShort = DateFormat('yyyy-MM-dd');
  
  /// Generate CSV content from measurements
  String generateCSV(List<Measurement> measurements, {String? equipmentName, String? pointName}) {
    final rows = <List<dynamic>>[];
    
    // Header row
    rows.add([
      'ID',
      'Timestamp',
      'Equipment',
      'Point',
      'Accel RMS (m/s²)',
      'Accel Peak (m/s²)',
      'Velocity RMS (mm/s)',
      'Velocity Peak (mm/s)',
      'Displacement RMS (μm)',
      'Displacement Peak (μm)',
      'Crest Factor',
      'Kurtosis',
      'ISO Zone',
      'Machine Class',
      'FFT Size',
      'Window',
      'Sample Rate (Hz)',
      'RPM',
      'Notes',
    ]);
    
    // Data rows
    for (final m in measurements) {
      rows.add([
        m.id,
        _dateFormat.format(m.timestamp),
        equipmentName ?? '',
        pointName ?? '',
        m.accelerationRms.toStringAsFixed(4),
        m.accelerationPeak.toStringAsFixed(4),
        m.velocityRms.toStringAsFixed(3),
        m.velocityPeak.toStringAsFixed(3),
        m.displacementRms.toStringAsFixed(2),
        m.displacementPeak.toStringAsFixed(2),
        m.crestFactor.toStringAsFixed(2),
        m.kurtosis.toStringAsFixed(2),
        m.isoZone,
        m.machineClass,
        m.fftSize,
        m.windowFunction,
        m.sampleRate,
        m.rpm?.toStringAsFixed(1) ?? '',
        m.notes ?? '',
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }
  
  /// Generate spectrum CSV
  String generateSpectrumCSV(Measurement measurement, List<double> frequencyAxis) {
    final rows = <List<dynamic>>[];
    
    rows.add(['Frequency (Hz)', 'Amplitude']);
    
    for (int i = 0; i < measurement.spectrumData.length && i < frequencyAxis.length; i++) {
      rows.add([
        frequencyAxis[i].toStringAsFixed(2),
        measurement.spectrumData[i].toStringAsFixed(6),
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }
  
  /// Generate PDF report
  Future<List<int>> generatePDFReport({
    required List<Measurement> measurements,
    String? equipmentName,
    String? locationName,
    String? pointName,
    String? notes,
  }) async {
    final pdf = pw.Document();
    
    // Title page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Vibration Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              _buildInfoSection(equipmentName, locationName, pointName),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildSummarySection(measurements),
              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(notes),
              ],
            ],
          );
        },
      ),
    );
    
    // Measurement details pages
    for (int i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Measurement ${i + 1}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Date: ${_dateFormat.format(m.timestamp)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                _buildMeasurementTable(m),
                pw.SizedBox(height: 20),
                _buildISOStatus(m),
                if (m.notes != null && m.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text('Notes: ${m.notes}'),
                ],
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }
  
  pw.Widget _buildInfoSection(String? equipment, String? location, String? point) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Report Information',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildInfoRow('Report Date', _dateFormat.format(DateTime.now())),
        if (equipment != null) _buildInfoRow('Equipment', equipment),
        if (location != null) _buildInfoRow('Location', location),
        if (point != null) _buildInfoRow('Measurement Point', point),
      ],
    );
  }
  
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }
  
  pw.Widget _buildSummarySection(List<Measurement> measurements) {
    if (measurements.isEmpty) {
      return pw.Text('No measurements available.');
    }
    
    // Calculate statistics
    final velocities = measurements.map((m) => m.velocityRms).toList();
    final avgVelocity = velocities.reduce((a, b) => a + b) / velocities.length;
    final maxVelocity = velocities.reduce((a, b) => a > b ? a : b);
    final minVelocity = velocities.reduce((a, b) => a < b ? a : b);
    
    // Count ISO zones
    final zoneCounts = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (final m in measurements) {
      zoneCounts[m.isoZone] = (zoneCounts[m.isoZone] ?? 0) + 1;
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary Statistics',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        _buildInfoRow('Total Measurements', measurements.length.toString()),
        _buildInfoRow('Date Range', 
          '${_dateFormatShort.format(measurements.last.timestamp)} - ${_dateFormatShort.format(measurements.first.timestamp)}'),
        pw.SizedBox(height: 10),
        pw.Text('Velocity Statistics (mm/s RMS):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildInfoRow('  Average', avgVelocity.toStringAsFixed(3)),
        _buildInfoRow('  Maximum', maxVelocity.toStringAsFixed(3)),
        _buildInfoRow('  Minimum', minVelocity.toStringAsFixed(3)),
        pw.SizedBox(height: 10),
        pw.Text('ISO 10816 Zone Distribution:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        _buildInfoRow('  Zone A (Good)', '${zoneCounts['A']} (${(zoneCounts['A']! / measurements.length * 100).toStringAsFixed(1)}%)'),
        _buildInfoRow('  Zone B (Satisfactory)', '${zoneCounts['B']} (${(zoneCounts['B']! / measurements.length * 100).toStringAsFixed(1)}%)'),
        _buildInfoRow('  Zone C (Unsatisfactory)', '${zoneCounts['C']} (${(zoneCounts['C']! / measurements.length * 100).toStringAsFixed(1)}%)'),
        _buildInfoRow('  Zone D (Unacceptable)', '${zoneCounts['D']} (${(zoneCounts['D']! / measurements.length * 100).toStringAsFixed(1)}%)'),
      ],
    );
  }
  
  pw.Widget _buildMeasurementTable(Measurement m) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        _buildTableRow('Parameter', 'RMS', 'Peak', true),
        _buildTableRow(
          'Acceleration',
          '${m.accelerationRms.toStringAsFixed(4)} m/s²\n${(m.accelerationRms / 9.80665).toStringAsFixed(4)} g',
          '${m.accelerationPeak.toStringAsFixed(4)} m/s²\n${(m.accelerationPeak / 9.80665).toStringAsFixed(4)} g',
          false,
        ),
        _buildTableRow(
          'Velocity',
          '${m.velocityRms.toStringAsFixed(3)} mm/s',
          '${m.velocityPeak.toStringAsFixed(3)} mm/s',
          false,
        ),
        _buildTableRow(
          'Displacement',
          '${m.displacementRms.toStringAsFixed(2)} μm',
          '${m.displacementPeak.toStringAsFixed(2)} μm',
          false,
        ),
        _buildTableRow('Crest Factor', m.crestFactor.toStringAsFixed(2), '-', false),
        _buildTableRow('Kurtosis', m.kurtosis.toStringAsFixed(2), '-', false),
      ],
    );
  }
  
  pw.TableRow _buildTableRow(String param, String rms, String peak, bool isHeader) {
    final style = isHeader
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)
        : const pw.TextStyle(fontSize: 10);
    
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(param, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(rms, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(peak, style: style),
        ),
      ],
    );
  }
  
  pw.Widget _buildISOStatus(Measurement m) {
    final zoneColors = {
      'A': PdfColors.green,
      'B': PdfColors.lightGreen,
      'C': PdfColors.amber,
      'D': PdfColors.red,
    };
    
    final zoneDescriptions = {
      'A': 'Good - Newly commissioned machines',
      'B': 'Satisfactory - Acceptable for long-term operation',
      'C': 'Unsatisfactory - Short-term operation only',
      'D': 'Unacceptable - May cause damage',
    };
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: zoneColors[m.isoZone] ?? PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ISO 10816 Assessment',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text('Machine Class: '),
              pw.Text(m.machineClass, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('Vibration Zone: '),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: zoneColors[m.isoZone],
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  'Zone ${m.isoZone}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: m.isoZone == 'D' ? PdfColors.white : PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            zoneDescriptions[m.isoZone] ?? '',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  /// Generate bearing fault frequency report
  String generateBearingReport({
    required String bearingName,
    required double rpm,
    required double bpfo,
    required double bpfi,
    required double bsf,
    required double ftf,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('====================================');
    buffer.writeln('BEARING FAULT FREQUENCY REPORT');
    buffer.writeln('====================================');
    buffer.writeln('');
    buffer.writeln('Bearing: $bearingName');
    buffer.writeln('Shaft Speed: ${rpm.toStringAsFixed(1)} RPM');
    buffer.writeln('Shaft Frequency: ${(rpm / 60).toStringAsFixed(2)} Hz');
    buffer.writeln('');
    buffer.writeln('CALCULATED FAULT FREQUENCIES:');
    buffer.writeln('------------------------------------');
    buffer.writeln('BPFO (Ball Pass Freq Outer): ${bpfo.toStringAsFixed(2)} Hz');
    buffer.writeln('BPFI (Ball Pass Freq Inner): ${bpfi.toStringAsFixed(2)} Hz');
    buffer.writeln('BSF  (Ball Spin Frequency):  ${bsf.toStringAsFixed(2)} Hz');
    buffer.writeln('FTF  (Cage Frequency):       ${ftf.toStringAsFixed(2)} Hz');
    buffer.writeln('');
    buffer.writeln('HARMONICS (2x, 3x):');
    buffer.writeln('------------------------------------');
    buffer.writeln('BPFO: ${bpfo.toStringAsFixed(2)}, ${(bpfo * 2).toStringAsFixed(2)}, ${(bpfo * 3).toStringAsFixed(2)} Hz');
    buffer.writeln('BPFI: ${bpfi.toStringAsFixed(2)}, ${(bpfi * 2).toStringAsFixed(2)}, ${(bpfi * 3).toStringAsFixed(2)} Hz');
    buffer.writeln('BSF:  ${bsf.toStringAsFixed(2)}, ${(bsf * 2).toStringAsFixed(2)}, ${(bsf * 3).toStringAsFixed(2)} Hz');
    buffer.writeln('');
    buffer.writeln('Report generated: ${_dateFormat.format(DateTime.now())}');
    
    return buffer.toString();
  }
}
