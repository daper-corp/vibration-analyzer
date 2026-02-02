/// Application-wide constants for Vibration Analyzer
class AppConstants {
  // App Info
  static const String appName = 'Vibration Analyzer';
  static const String appVersion = '1.0.0';
  
  // Sampling Configuration
  static const int defaultSampleRate = 200; // Hz (target)
  static const int minSampleRate = 50;
  static const int maxSampleRate = 500;
  
  // FFT Configuration
  static const List<int> fftSizes = [1024, 2048, 4096];
  static const int defaultFftSize = 2048;
  
  // Window Functions
  static const String windowHanning = 'Hanning';
  static const String windowHamming = 'Hamming';
  static const String windowFlatTop = 'Flat-Top';
  static const String windowRectangular = 'Rectangular';
  static const List<String> windowFunctions = [
    windowHanning,
    windowHamming,
    windowFlatTop,
    windowRectangular,
  ];
  
  // Averaging Types
  static const String avgLinear = 'Linear';
  static const String avgExponential = 'Exponential';
  static const List<String> averagingTypes = [avgLinear, avgExponential];
  static const List<int> averageCounts = [1, 2, 4, 8, 16, 32];
  
  // Measurement Units
  static const String unitAccelMps2 = 'm/s²';
  static const String unitAccelG = 'g';
  static const String unitVelocity = 'mm/s';
  static const String unitDisplacement = 'μm';
  
  // Physical Constants
  static const double gravity = 9.80665; // m/s²
  
  // ISO 10816 Machine Classes
  static const String machineClass1 = 'Class I'; // Small machines
  static const String machineClass2 = 'Class II'; // Medium machines
  static const String machineClass3 = 'Class III'; // Large machines (rigid)
  static const String machineClass4 = 'Class IV'; // Large machines (soft)
  
  // ISO 10816-1 Vibration Severity Zones (mm/s RMS)
  // Class I: Small machines (up to 15 kW)
  static const Map<String, List<double>> isoClass1Limits = {
    'A': [0.0, 0.71],     // Good
    'B': [0.71, 1.8],     // Satisfactory
    'C': [1.8, 4.5],      // Unsatisfactory
    'D': [4.5, double.infinity], // Unacceptable
  };
  
  // Class II: Medium machines (15-75 kW)
  static const Map<String, List<double>> isoClass2Limits = {
    'A': [0.0, 1.12],
    'B': [1.12, 2.8],
    'C': [2.8, 7.1],
    'D': [7.1, double.infinity],
  };
  
  // Class III: Large machines, rigid foundation (>75 kW)
  static const Map<String, List<double>> isoClass3Limits = {
    'A': [0.0, 1.8],
    'B': [1.8, 4.5],
    'C': [4.5, 11.2],
    'D': [11.2, double.infinity],
  };
  
  // Class IV: Large machines, soft foundation
  static const Map<String, List<double>> isoClass4Limits = {
    'A': [0.0, 2.8],
    'B': [2.8, 7.1],
    'C': [7.1, 18.0],
    'D': [18.0, double.infinity],
  };
  
  // Zone Descriptions
  static const Map<String, String> zoneDescriptions = {
    'A': 'Good - Newly commissioned machines',
    'B': 'Satisfactory - Acceptable for long-term operation',
    'C': 'Unsatisfactory - Short-term operation only',
    'D': 'Unacceptable - May cause damage',
  };
  
  // Frequency Analysis Ranges
  static const double minAnalysisFreq = 10.0;   // Hz
  static const double maxAnalysisFreq = 1000.0; // Hz
  
  // Common Fault Frequencies
  static const String faultUnbalance = 'Unbalance';
  static const String faultMisalignment = 'Misalignment';
  static const String faultLooseness = 'Looseness';
  static const String faultBearing = 'Bearing';
  static const String faultGear = 'Gear';
  
  // Bearing Fault Types
  static const String bpfo = 'BPFO'; // Ball Pass Frequency Outer
  static const String bpfi = 'BPFI'; // Ball Pass Frequency Inner
  static const String bsf = 'BSF';   // Ball Spin Frequency
  static const String ftf = 'FTF';   // Fundamental Train Frequency
  
  // Data Storage
  static const String hiveBoxMeasurements = 'measurements';
  static const String hiveBoxEquipment = 'equipment';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxBearings = 'bearings';
  
  // Chart Configuration
  static const int maxChartPoints = 1024;
  static const int waveformDisplayPoints = 512;
  static const int spectrumDisplayPoints = 512;
  
  // UI Configuration
  static const double largeButtonMinSize = 60.0;
  static const double measurementFontSize = 48.0;
  static const double unitFontSize = 16.0;
  
  // Export Configuration
  static const String csvDelimiter = ',';
  static const String pdfTitle = 'Vibration Analysis Report';
}

/// Bearing geometry parameters for fault frequency calculation
class BearingGeometry {
  final String name;
  final int rollingElements;    // Number of rolling elements (balls/rollers)
  final double pitchDiameter;   // Pitch diameter (mm)
  final double elementDiameter; // Rolling element diameter (mm)
  final double contactAngle;    // Contact angle (degrees)
  
  const BearingGeometry({
    required this.name,
    required this.rollingElements,
    required this.pitchDiameter,
    required this.elementDiameter,
    required this.contactAngle,
  });
  
  /// Calculate BPFO (Ball Pass Frequency Outer Race)
  double calculateBPFO(double rpm) {
    final n = rollingElements;
    final fr = rpm / 60.0; // Shaft frequency in Hz
    final d = elementDiameter;
    final D = pitchDiameter;
    final theta = contactAngle * 3.14159265359 / 180.0;
    return (n / 2) * fr * (1 - (d / D) * _cos(theta));
  }
  
  /// Calculate BPFI (Ball Pass Frequency Inner Race)
  double calculateBPFI(double rpm) {
    final n = rollingElements;
    final fr = rpm / 60.0;
    final d = elementDiameter;
    final D = pitchDiameter;
    final theta = contactAngle * 3.14159265359 / 180.0;
    return (n / 2) * fr * (1 + (d / D) * _cos(theta));
  }
  
  /// Calculate BSF (Ball Spin Frequency)
  double calculateBSF(double rpm) {
    final fr = rpm / 60.0;
    final d = elementDiameter;
    final D = pitchDiameter;
    final theta = contactAngle * 3.14159265359 / 180.0;
    return (D / (2 * d)) * fr * (1 - _pow((d / D) * _cos(theta), 2));
  }
  
  /// Calculate FTF (Fundamental Train Frequency / Cage Frequency)
  double calculateFTF(double rpm) {
    final fr = rpm / 60.0;
    final d = elementDiameter;
    final D = pitchDiameter;
    final theta = contactAngle * 3.14159265359 / 180.0;
    return (fr / 2) * (1 - (d / D) * _cos(theta));
  }
  
  // Simple math helpers to avoid importing dart:math
  double _cos(double x) {
    // Taylor series approximation for cos
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
  
  double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}

/// Common bearing database
class BearingDatabase {
  static const List<BearingGeometry> commonBearings = [
    BearingGeometry(
      name: '6205 (Generic Deep Groove)',
      rollingElements: 9,
      pitchDiameter: 39.0,
      elementDiameter: 7.94,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6206',
      rollingElements: 9,
      pitchDiameter: 46.0,
      elementDiameter: 9.53,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6207',
      rollingElements: 9,
      pitchDiameter: 53.5,
      elementDiameter: 11.11,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6208',
      rollingElements: 9,
      pitchDiameter: 60.0,
      elementDiameter: 12.3,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6209',
      rollingElements: 10,
      pitchDiameter: 67.5,
      elementDiameter: 12.7,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6210',
      rollingElements: 10,
      pitchDiameter: 75.0,
      elementDiameter: 14.29,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6305',
      rollingElements: 7,
      pitchDiameter: 43.5,
      elementDiameter: 11.11,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '6306',
      rollingElements: 8,
      pitchDiameter: 52.0,
      elementDiameter: 12.7,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: '7205 (Angular Contact)',
      rollingElements: 12,
      pitchDiameter: 39.0,
      elementDiameter: 6.35,
      contactAngle: 25,
    ),
    BearingGeometry(
      name: '7206 (Angular Contact)',
      rollingElements: 13,
      pitchDiameter: 46.0,
      elementDiameter: 7.14,
      contactAngle: 25,
    ),
    BearingGeometry(
      name: 'NU205 (Cylindrical Roller)',
      rollingElements: 13,
      pitchDiameter: 39.5,
      elementDiameter: 7.5,
      contactAngle: 0,
    ),
    BearingGeometry(
      name: 'NU206 (Cylindrical Roller)',
      rollingElements: 13,
      pitchDiameter: 46.5,
      elementDiameter: 9.0,
      contactAngle: 0,
    ),
  ];
}
