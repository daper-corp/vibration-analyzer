// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementAdapter extends TypeAdapter<Measurement> {
  @override
  final int typeId = 0;

  @override
  Measurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Measurement(
      id: fields[0] as String,
      pointId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      accelerationRms: fields[3] as double,
      accelerationPeak: fields[4] as double,
      velocityRms: fields[5] as double,
      velocityPeak: fields[6] as double,
      displacementRms: fields[7] as double,
      displacementPeak: fields[8] as double,
      crestFactor: fields[9] as double,
      kurtosis: fields[10] as double,
      isoZone: fields[11] as String,
      machineClass: fields[12] as String,
      spectrumData: (fields[13] as List).cast<double>(),
      waveformData: (fields[14] as List).cast<double>(),
      fftSize: fields[15] as int,
      windowFunction: fields[16] as String,
      sampleRate: fields[17] as int,
      notes: fields[18] as String?,
      imagePath: fields[19] as String?,
      rpm: fields[20] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Measurement obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.pointId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.accelerationRms)
      ..writeByte(4)
      ..write(obj.accelerationPeak)
      ..writeByte(5)
      ..write(obj.velocityRms)
      ..writeByte(6)
      ..write(obj.velocityPeak)
      ..writeByte(7)
      ..write(obj.displacementRms)
      ..writeByte(8)
      ..write(obj.displacementPeak)
      ..writeByte(9)
      ..write(obj.crestFactor)
      ..writeByte(10)
      ..write(obj.kurtosis)
      ..writeByte(11)
      ..write(obj.isoZone)
      ..writeByte(12)
      ..write(obj.machineClass)
      ..writeByte(13)
      ..write(obj.spectrumData)
      ..writeByte(14)
      ..write(obj.waveformData)
      ..writeByte(15)
      ..write(obj.fftSize)
      ..writeByte(16)
      ..write(obj.windowFunction)
      ..writeByte(17)
      ..write(obj.sampleRate)
      ..writeByte(18)
      ..write(obj.notes)
      ..writeByte(19)
      ..write(obj.imagePath)
      ..writeByte(20)
      ..write(obj.rpm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EquipmentAdapter extends TypeAdapter<Equipment> {
  @override
  final int typeId = 1;

  @override
  Equipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Equipment(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      machineClass: fields[3] as String,
      nominalRpm: fields[4] as double?,
      manufacturer: fields[5] as String?,
      model: fields[6] as String?,
      serialNumber: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      imagePath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Equipment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.machineClass)
      ..writeByte(4)
      ..write(obj.nominalRpm)
      ..writeByte(5)
      ..write(obj.manufacturer)
      ..writeByte(6)
      ..write(obj.model)
      ..writeByte(7)
      ..write(obj.serialNumber)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementLocationAdapter extends TypeAdapter<MeasurementLocation> {
  @override
  final int typeId = 2;

  @override
  MeasurementLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementLocation(
      id: fields[0] as String,
      equipmentId: fields[1] as String,
      name: fields[2] as String,
      description: fields[3] as String?,
      imagePath: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.equipmentId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementPointAdapter extends TypeAdapter<MeasurementPoint> {
  @override
  final int typeId = 3;

  @override
  MeasurementPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementPoint(
      id: fields[0] as String,
      locationId: fields[1] as String,
      name: fields[2] as String,
      direction: fields[3] as String,
      bearingType: fields[4] as String?,
      description: fields[5] as String?,
      imagePath: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementPoint obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.locationId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.direction)
      ..writeByte(4)
      ..write(obj.bearingType)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedBearingAdapter extends TypeAdapter<SavedBearing> {
  @override
  final int typeId = 4;

  @override
  SavedBearing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedBearing(
      id: fields[0] as String,
      name: fields[1] as String,
      rollingElements: fields[2] as int,
      pitchDiameter: fields[3] as double,
      elementDiameter: fields[4] as double,
      contactAngle: fields[5] as double,
      isCustom: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavedBearing obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.rollingElements)
      ..writeByte(3)
      ..write(obj.pitchDiameter)
      ..writeByte(4)
      ..write(obj.elementDiameter)
      ..writeByte(5)
      ..write(obj.contactAngle)
      ..writeByte(6)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedBearingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      sampleRate: fields[0] as int,
      fftSize: fields[1] as int,
      windowFunction: fields[2] as String,
      averageType: fields[3] as String,
      averageCount: fields[4] as int,
      defaultMachineClass: fields[5] as String,
      vibrateFeedback: fields[6] as bool,
      keepScreenOn: fields[7] as bool,
      displayUnit: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.sampleRate)
      ..writeByte(1)
      ..write(obj.fftSize)
      ..writeByte(2)
      ..write(obj.windowFunction)
      ..writeByte(3)
      ..write(obj.averageType)
      ..writeByte(4)
      ..write(obj.averageCount)
      ..writeByte(5)
      ..write(obj.defaultMachineClass)
      ..writeByte(6)
      ..write(obj.vibrateFeedback)
      ..writeByte(7)
      ..write(obj.keepScreenOn)
      ..writeByte(8)
      ..write(obj.displayUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
