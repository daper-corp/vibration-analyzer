import 'package:hive_flutter/hive_flutter.dart';
import '../models/measurement.dart';
import '../constants/app_constants.dart';

/// Local storage service using Hive
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  late Box<Measurement> _measurementsBox;
  late Box<Equipment> _equipmentBox;
  late Box<MeasurementLocation> _locationsBox;
  late Box<MeasurementPoint> _pointsBox;
  late Box<SavedBearing> _bearingsBox;
  late Box<AppSettings> _settingsBox;
  
  bool _isInitialized = false;
  
  /// Initialize Hive storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MeasurementAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EquipmentAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MeasurementLocationAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MeasurementPointAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SavedBearingAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    
    // Open boxes
    _measurementsBox = await Hive.openBox<Measurement>(AppConstants.hiveBoxMeasurements);
    _equipmentBox = await Hive.openBox<Equipment>(AppConstants.hiveBoxEquipment);
    _locationsBox = await Hive.openBox<MeasurementLocation>('locations');
    _pointsBox = await Hive.openBox<MeasurementPoint>('points');
    _bearingsBox = await Hive.openBox<SavedBearing>(AppConstants.hiveBoxBearings);
    _settingsBox = await Hive.openBox<AppSettings>(AppConstants.hiveBoxSettings);
    
    _isInitialized = true;
  }
  
  // ==================== Measurements ====================
  
  /// Save measurement
  Future<void> saveMeasurement(Measurement measurement) async {
    await _measurementsBox.put(measurement.id, measurement);
  }
  
  /// Get all measurements
  List<Measurement> getAllMeasurements() {
    return _measurementsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Get measurements for a specific point
  List<Measurement> getMeasurementsForPoint(String pointId) {
    return _measurementsBox.values
        .where((m) => m.pointId == pointId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Get recent measurements
  List<Measurement> getRecentMeasurements({int limit = 50}) {
    final all = getAllMeasurements();
    return all.take(limit).toList();
  }
  
  /// Delete measurement
  Future<void> deleteMeasurement(String id) async {
    await _measurementsBox.delete(id);
  }
  
  /// Get measurement by ID
  Measurement? getMeasurement(String id) {
    return _measurementsBox.get(id);
  }
  
  // ==================== Equipment ====================
  
  /// Save equipment
  Future<void> saveEquipment(Equipment equipment) async {
    await _equipmentBox.put(equipment.id, equipment);
  }
  
  /// Get all equipment
  List<Equipment> getAllEquipment() {
    return _equipmentBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  /// Get equipment by ID
  Equipment? getEquipment(String id) {
    return _equipmentBox.get(id);
  }
  
  /// Delete equipment and related data
  Future<void> deleteEquipment(String id) async {
    // Delete related locations and their points
    final locations = getLocationsForEquipment(id);
    for (final location in locations) {
      await deleteLocation(location.id);
    }
    await _equipmentBox.delete(id);
  }
  
  // ==================== Locations ====================
  
  /// Save location
  Future<void> saveLocation(MeasurementLocation location) async {
    await _locationsBox.put(location.id, location);
  }
  
  /// Get locations for equipment
  List<MeasurementLocation> getLocationsForEquipment(String equipmentId) {
    return _locationsBox.values
        .where((l) => l.equipmentId == equipmentId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  /// Get location by ID
  MeasurementLocation? getLocation(String id) {
    return _locationsBox.get(id);
  }
  
  /// Delete location and related points
  Future<void> deleteLocation(String id) async {
    final points = getPointsForLocation(id);
    for (final point in points) {
      await deletePoint(point.id);
    }
    await _locationsBox.delete(id);
  }
  
  // ==================== Measurement Points ====================
  
  /// Save measurement point
  Future<void> savePoint(MeasurementPoint point) async {
    await _pointsBox.put(point.id, point);
  }
  
  /// Get points for location
  List<MeasurementPoint> getPointsForLocation(String locationId) {
    return _pointsBox.values
        .where((p) => p.locationId == locationId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  /// Get all points
  List<MeasurementPoint> getAllPoints() {
    return _pointsBox.values.toList();
  }
  
  /// Get point by ID
  MeasurementPoint? getPoint(String id) {
    return _pointsBox.get(id);
  }
  
  /// Delete point and related measurements
  Future<void> deletePoint(String id) async {
    final measurements = getMeasurementsForPoint(id);
    for (final m in measurements) {
      await deleteMeasurement(m.id);
    }
    await _pointsBox.delete(id);
  }
  
  // ==================== Bearings ====================
  
  /// Save bearing configuration
  Future<void> saveBearing(SavedBearing bearing) async {
    await _bearingsBox.put(bearing.id, bearing);
  }
  
  /// Get all saved bearings
  List<SavedBearing> getAllBearings() {
    return _bearingsBox.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  /// Get bearing by ID
  SavedBearing? getBearing(String id) {
    return _bearingsBox.get(id);
  }
  
  /// Delete bearing
  Future<void> deleteBearing(String id) async {
    await _bearingsBox.delete(id);
  }
  
  // ==================== Settings ====================
  
  /// Get app settings
  AppSettings getSettings() {
    return _settingsBox.get('settings') ?? AppSettings();
  }
  
  /// Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings);
  }
  
  // ==================== Statistics ====================
  
  /// Get measurement statistics for a point (for trend analysis)
  Map<String, dynamic> getPointStatistics(String pointId) {
    final measurements = getMeasurementsForPoint(pointId);
    if (measurements.isEmpty) {
      return {
        'count': 0,
        'avgVelocity': 0.0,
        'maxVelocity': 0.0,
        'minVelocity': 0.0,
        'trend': 'stable',
      };
    }
    
    final velocities = measurements.map((m) => m.velocityRms).toList();
    final avgVelocity = velocities.reduce((a, b) => a + b) / velocities.length;
    final maxVelocity = velocities.reduce((a, b) => a > b ? a : b);
    final minVelocity = velocities.reduce((a, b) => a < b ? a : b);
    
    // Simple trend analysis (last 5 measurements)
    String trend = 'stable';
    if (measurements.length >= 3) {
      final recent = measurements.take(3).map((m) => m.velocityRms).toList();
      final older = measurements.skip(3).take(3).map((m) => m.velocityRms).toList();
      
      if (older.isNotEmpty) {
        final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
        final olderAvg = older.reduce((a, b) => a + b) / older.length;
        
        if (recentAvg > olderAvg * 1.2) {
          trend = 'increasing';
        } else if (recentAvg < olderAvg * 0.8) {
          trend = 'decreasing';
        }
      }
    }
    
    return {
      'count': measurements.length,
      'avgVelocity': avgVelocity,
      'maxVelocity': maxVelocity,
      'minVelocity': minVelocity,
      'trend': trend,
      'lastMeasurement': measurements.first.timestamp,
    };
  }
  
  /// Clear all data
  Future<void> clearAllData() async {
    await _measurementsBox.clear();
    await _equipmentBox.clear();
    await _locationsBox.clear();
    await _pointsBox.clear();
  }
  
  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
