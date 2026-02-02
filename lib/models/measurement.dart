import 'package:hive/hive.dart';

part 'measurement.g.dart';

/// Vibration measurement data model
@HiveType(typeId: 0)
class Measurement extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String pointId;
  
  @HiveField(2)
  final DateTime timestamp;
  
  @HiveField(3)
  final double accelerationRms; // m/s²
  
  @HiveField(4)
  final double accelerationPeak; // m/s²
  
  @HiveField(5)
  final double velocityRms; // mm/s
  
  @HiveField(6)
  final double velocityPeak; // mm/s
  
  @HiveField(7)
  final double displacementRms; // μm
  
  @HiveField(8)
  final double displacementPeak; // μm
  
  @HiveField(9)
  final double crestFactor;
  
  @HiveField(10)
  final double kurtosis;
  
  @HiveField(11)
  final String isoZone; // A, B, C, D
  
  @HiveField(12)
  final String machineClass; // Class I, II, III, IV
  
  @HiveField(13)
  final List<double> spectrumData;
  
  @HiveField(14)
  final List<double> waveformData;
  
  @HiveField(15)
  final int fftSize;
  
  @HiveField(16)
  final String windowFunction;
  
  @HiveField(17)
  final int sampleRate;
  
  @HiveField(18)
  final String? notes;
  
  @HiveField(19)
  final String? imagePath;
  
  @HiveField(20)
  final double? rpm; // Shaft speed for bearing analysis
  
  Measurement({
    required this.id,
    required this.pointId,
    required this.timestamp,
    required this.accelerationRms,
    required this.accelerationPeak,
    required this.velocityRms,
    required this.velocityPeak,
    required this.displacementRms,
    required this.displacementPeak,
    required this.crestFactor,
    required this.kurtosis,
    required this.isoZone,
    required this.machineClass,
    required this.spectrumData,
    required this.waveformData,
    required this.fftSize,
    required this.windowFunction,
    required this.sampleRate,
    this.notes,
    this.imagePath,
    this.rpm,
  });
  
  /// Create a copy with modifications
  Measurement copyWith({
    String? id,
    String? pointId,
    DateTime? timestamp,
    double? accelerationRms,
    double? accelerationPeak,
    double? velocityRms,
    double? velocityPeak,
    double? displacementRms,
    double? displacementPeak,
    double? crestFactor,
    double? kurtosis,
    String? isoZone,
    String? machineClass,
    List<double>? spectrumData,
    List<double>? waveformData,
    int? fftSize,
    String? windowFunction,
    int? sampleRate,
    String? notes,
    String? imagePath,
    double? rpm,
  }) {
    return Measurement(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      timestamp: timestamp ?? this.timestamp,
      accelerationRms: accelerationRms ?? this.accelerationRms,
      accelerationPeak: accelerationPeak ?? this.accelerationPeak,
      velocityRms: velocityRms ?? this.velocityRms,
      velocityPeak: velocityPeak ?? this.velocityPeak,
      displacementRms: displacementRms ?? this.displacementRms,
      displacementPeak: displacementPeak ?? this.displacementPeak,
      crestFactor: crestFactor ?? this.crestFactor,
      kurtosis: kurtosis ?? this.kurtosis,
      isoZone: isoZone ?? this.isoZone,
      machineClass: machineClass ?? this.machineClass,
      spectrumData: spectrumData ?? this.spectrumData,
      waveformData: waveformData ?? this.waveformData,
      fftSize: fftSize ?? this.fftSize,
      windowFunction: windowFunction ?? this.windowFunction,
      sampleRate: sampleRate ?? this.sampleRate,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      rpm: rpm ?? this.rpm,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pointId': pointId,
      'timestamp': timestamp.toIso8601String(),
      'accelerationRms': accelerationRms,
      'accelerationPeak': accelerationPeak,
      'velocityRms': velocityRms,
      'velocityPeak': velocityPeak,
      'displacementRms': displacementRms,
      'displacementPeak': displacementPeak,
      'crestFactor': crestFactor,
      'kurtosis': kurtosis,
      'isoZone': isoZone,
      'machineClass': machineClass,
      'fftSize': fftSize,
      'windowFunction': windowFunction,
      'sampleRate': sampleRate,
      'notes': notes,
      'rpm': rpm,
    };
  }
}

/// Equipment/Machine model
@HiveType(typeId: 1)
class Equipment extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String machineClass; // Class I, II, III, IV
  
  @HiveField(4)
  final double? nominalRpm;
  
  @HiveField(5)
  final String? manufacturer;
  
  @HiveField(6)
  final String? model;
  
  @HiveField(7)
  final String? serialNumber;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final String? imagePath;
  
  Equipment({
    required this.id,
    required this.name,
    this.description,
    required this.machineClass,
    this.nominalRpm,
    this.manufacturer,
    this.model,
    this.serialNumber,
    required this.createdAt,
    this.imagePath,
  });
  
  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? machineClass,
    double? nominalRpm,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? createdAt,
    String? imagePath,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      machineClass: machineClass ?? this.machineClass,
      nominalRpm: nominalRpm ?? this.nominalRpm,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Location within equipment
@HiveType(typeId: 2)
class MeasurementLocation extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String equipmentId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final String? imagePath;
  
  MeasurementLocation({
    required this.id,
    required this.equipmentId,
    required this.name,
    this.description,
    this.imagePath,
  });
  
  MeasurementLocation copyWith({
    String? id,
    String? equipmentId,
    String? name,
    String? description,
    String? imagePath,
  }) {
    return MeasurementLocation(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Measurement point within a location
@HiveType(typeId: 3)
class MeasurementPoint extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String locationId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String direction; // Horizontal, Vertical, Axial
  
  @HiveField(4)
  final String? bearingType;
  
  @HiveField(5)
  final String? description;
  
  @HiveField(6)
  final String? imagePath;
  
  MeasurementPoint({
    required this.id,
    required this.locationId,
    required this.name,
    required this.direction,
    this.bearingType,
    this.description,
    this.imagePath,
  });
  
  MeasurementPoint copyWith({
    String? id,
    String? locationId,
    String? name,
    String? direction,
    String? bearingType,
    String? description,
    String? imagePath,
  }) {
    return MeasurementPoint(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      bearingType: bearingType ?? this.bearingType,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Saved bearing configuration
@HiveType(typeId: 4)
class SavedBearing extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final int rollingElements;
  
  @HiveField(3)
  final double pitchDiameter;
  
  @HiveField(4)
  final double elementDiameter;
  
  @HiveField(5)
  final double contactAngle;
  
  @HiveField(6)
  final bool isCustom;
  
  SavedBearing({
    required this.id,
    required this.name,
    required this.rollingElements,
    required this.pitchDiameter,
    required this.elementDiameter,
    required this.contactAngle,
    this.isCustom = false,
  });
}

/// App settings
@HiveType(typeId: 5)
class AppSettings extends HiveObject {
  @HiveField(0)
  final int sampleRate;
  
  @HiveField(1)
  final int fftSize;
  
  @HiveField(2)
  final String windowFunction;
  
  @HiveField(3)
  final String averageType;
  
  @HiveField(4)
  final int averageCount;
  
  @HiveField(5)
  final String defaultMachineClass;
  
  @HiveField(6)
  final bool vibrateFeedback;
  
  @HiveField(7)
  final bool keepScreenOn;
  
  @HiveField(8)
  final String displayUnit; // 'm/s²' or 'g'
  
  AppSettings({
    this.sampleRate = 200,
    this.fftSize = 2048,
    this.windowFunction = 'Hanning',
    this.averageType = 'Linear',
    this.averageCount = 4,
    this.defaultMachineClass = 'Class II',
    this.vibrateFeedback = true,
    this.keepScreenOn = true,
    this.displayUnit = 'g',
  });
  
  AppSettings copyWith({
    int? sampleRate,
    int? fftSize,
    String? windowFunction,
    String? averageType,
    int? averageCount,
    String? defaultMachineClass,
    bool? vibrateFeedback,
    bool? keepScreenOn,
    String? displayUnit,
  }) {
    return AppSettings(
      sampleRate: sampleRate ?? this.sampleRate,
      fftSize: fftSize ?? this.fftSize,
      windowFunction: windowFunction ?? this.windowFunction,
      averageType: averageType ?? this.averageType,
      averageCount: averageCount ?? this.averageCount,
      defaultMachineClass: defaultMachineClass ?? this.defaultMachineClass,
      vibrateFeedback: vibrateFeedback ?? this.vibrateFeedback,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      displayUnit: displayUnit ?? this.displayUnit,
    );
  }
}
