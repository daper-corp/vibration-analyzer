import 'package:flutter/foundation.dart';
import '../models/measurement.dart';
import '../services/storage_service.dart';
import '../services/vibration_analyzer_service.dart';
import '../utils/logger.dart';

/// Main application state provider
class AppProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  late final dynamic _vibrationService;
  
  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // Current selections
  Equipment? _selectedEquipment;
  MeasurementLocation? _selectedLocation;
  MeasurementPoint? _selectedPoint;
  
  // Data lists
  List<Equipment> _equipment = [];
  List<MeasurementLocation> _locations = [];
  List<MeasurementPoint> _points = [];
  List<Measurement> _measurements = [];
  
  // Settings
  AppSettings _settings = AppSettings();
  
  // Measurement state
  MeasurementState _measurementState = MeasurementState.idle;
  MeasurementResult? _lastResult;
  double _measurementProgress = 0;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Equipment? get selectedEquipment => _selectedEquipment;
  MeasurementLocation? get selectedLocation => _selectedLocation;
  MeasurementPoint? get selectedPoint => _selectedPoint;
  
  List<Equipment> get equipment => _equipment;
  List<MeasurementLocation> get locations => _locations;
  List<MeasurementPoint> get points => _points;
  List<Measurement> get measurements => _measurements;
  
  AppSettings get settings => _settings;
  
  MeasurementState get measurementState => _measurementState;
  MeasurementResult? get lastResult => _lastResult;
  double get measurementProgress => _measurementProgress;
  
  dynamic get vibrationService => _vibrationService;
  
  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    
    try {
      log.i(LogTags.storage, 'Initializing storage service');
      // Initialize storage
      await _storageService.initialize();
      log.i(LogTags.storage, 'Storage service initialized successfully');
      
      // Initialize vibration service (simulated for web)
      if (kIsWeb) {
        log.i(LogTags.sensor, 'Running on Web - using simulated vibration service');
        _vibrationService = SimulatedVibrationService();
      } else {
        log.i(LogTags.sensor, 'Running on Mobile - using real sensor service');
        _vibrationService = VibrationAnalyzerService();
      }
      _vibrationService.initialize();
      log.i(LogTags.sensor, 'Vibration service initialized');
      
      // Listen to vibration service streams
      _vibrationService.stateStream.listen((state) {
        _measurementState = state;
        notifyListeners();
      });
      
      _vibrationService.progressStream.listen((progress) {
        _measurementProgress = progress;
        notifyListeners();
      });
      
      // Load initial data
      await _loadData();
      
      // Load settings
      _settings = _storageService.getSettings();
      _applySettings();
      
      _isInitialized = true;
      log.i(LogTags.measurement, 'App initialization complete');
    } catch (e, stackTrace) {
      log.e(LogTags.measurement, 'Initialization failed', e, stackTrace);
      _error = 'Initialization failed: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _loadData() async {
    _equipment = _storageService.getAllEquipment();
    
    // Create demo data if empty
    if (_equipment.isEmpty) {
      await _createDemoData();
      _equipment = _storageService.getAllEquipment();
    }
    
    notifyListeners();
  }
  
  Future<void> _createDemoData() async {
    // Create demo equipment
    final pump = Equipment(
      id: 'eq_001',
      name: 'Cooling Water Pump #1',
      description: '75kW centrifugal pump',
      machineClass: 'Class III',
      nominalRpm: 1480,
      manufacturer: 'KSB',
      model: 'Etanorm 100-200',
      serialNumber: 'CWP-2024-001',
      createdAt: DateTime.now(),
    );
    await _storageService.saveEquipment(pump);
    
    // Create locations
    final driveSide = MeasurementLocation(
      id: 'loc_001',
      equipmentId: pump.id,
      name: 'Drive End Bearing',
      description: 'Motor side bearing housing',
    );
    await _storageService.saveLocation(driveSide);
    
    final nonDriveSide = MeasurementLocation(
      id: 'loc_002',
      equipmentId: pump.id,
      name: 'Non-Drive End Bearing',
      description: 'Pump side bearing housing',
    );
    await _storageService.saveLocation(nonDriveSide);
    
    // Create measurement points
    final points = [
      MeasurementPoint(
        id: 'pt_001',
        locationId: driveSide.id,
        name: '1H',
        direction: 'Horizontal',
        bearingType: '6208',
      ),
      MeasurementPoint(
        id: 'pt_002',
        locationId: driveSide.id,
        name: '1V',
        direction: 'Vertical',
        bearingType: '6208',
      ),
      MeasurementPoint(
        id: 'pt_003',
        locationId: driveSide.id,
        name: '1A',
        direction: 'Axial',
        bearingType: '6208',
      ),
      MeasurementPoint(
        id: 'pt_004',
        locationId: nonDriveSide.id,
        name: '2H',
        direction: 'Horizontal',
        bearingType: '6206',
      ),
      MeasurementPoint(
        id: 'pt_005',
        locationId: nonDriveSide.id,
        name: '2V',
        direction: 'Vertical',
        bearingType: '6206',
      ),
    ];
    
    for (final point in points) {
      await _storageService.savePoint(point);
    }
    
    // Create second equipment
    final motor = Equipment(
      id: 'eq_002',
      name: 'Air Compressor Motor',
      description: '45kW induction motor',
      machineClass: 'Class II',
      nominalRpm: 2960,
      manufacturer: 'ABB',
      model: 'M3BP 200MLA',
      serialNumber: 'ACM-2024-002',
      createdAt: DateTime.now(),
    );
    await _storageService.saveEquipment(motor);
  }
  
  void _applySettings() {
    _vibrationService.configure(
      sampleRate: _settings.sampleRate,
      fftSize: _settings.fftSize,
      windowFunction: _settings.windowFunction,
      averageType: _settings.averageType,
      averageCount: _settings.averageCount,
      machineClass: _settings.defaultMachineClass,
    );
  }
  
  // ==================== Equipment Management ====================
  
  void selectEquipment(Equipment? equipment) {
    _selectedEquipment = equipment;
    _selectedLocation = null;
    _selectedPoint = null;
    _locations = [];
    _points = [];
    _measurements = [];
    
    if (equipment != null) {
      _locations = _storageService.getLocationsForEquipment(equipment.id);
    }
    
    notifyListeners();
  }
  
  Future<void> addEquipment(Equipment equipment) async {
    await _storageService.saveEquipment(equipment);
    _equipment = _storageService.getAllEquipment();
    notifyListeners();
  }
  
  Future<void> updateEquipment(Equipment equipment) async {
    await _storageService.saveEquipment(equipment);
    _equipment = _storageService.getAllEquipment();
    if (_selectedEquipment?.id == equipment.id) {
      _selectedEquipment = equipment;
    }
    notifyListeners();
  }
  
  Future<void> deleteEquipment(String id) async {
    await _storageService.deleteEquipment(id);
    _equipment = _storageService.getAllEquipment();
    if (_selectedEquipment?.id == id) {
      selectEquipment(null);
    }
    notifyListeners();
  }
  
  // ==================== Location Management ====================
  
  void selectLocation(MeasurementLocation? location) {
    _selectedLocation = location;
    _selectedPoint = null;
    _points = [];
    _measurements = [];
    
    if (location != null) {
      _points = _storageService.getPointsForLocation(location.id);
    }
    
    notifyListeners();
  }
  
  Future<void> addLocation(MeasurementLocation location) async {
    await _storageService.saveLocation(location);
    if (_selectedEquipment != null) {
      _locations = _storageService.getLocationsForEquipment(_selectedEquipment!.id);
    }
    notifyListeners();
  }
  
  Future<void> deleteLocation(String id) async {
    await _storageService.deleteLocation(id);
    if (_selectedEquipment != null) {
      _locations = _storageService.getLocationsForEquipment(_selectedEquipment!.id);
    }
    if (_selectedLocation?.id == id) {
      selectLocation(null);
    }
    notifyListeners();
  }
  
  // ==================== Point Management ====================
  
  void selectPoint(MeasurementPoint? point) {
    _selectedPoint = point;
    _measurements = [];
    
    if (point != null) {
      _measurements = _storageService.getMeasurementsForPoint(point.id);
    }
    
    notifyListeners();
  }
  
  Future<void> addPoint(MeasurementPoint point) async {
    await _storageService.savePoint(point);
    if (_selectedLocation != null) {
      _points = _storageService.getPointsForLocation(_selectedLocation!.id);
    }
    notifyListeners();
  }
  
  Future<void> deletePoint(String id) async {
    await _storageService.deletePoint(id);
    if (_selectedLocation != null) {
      _points = _storageService.getPointsForLocation(_selectedLocation!.id);
    }
    if (_selectedPoint?.id == id) {
      selectPoint(null);
    }
    notifyListeners();
  }
  
  // ==================== Measurement ====================
  
  Future<void> startMeasurement() async {
    if (_measurementState != MeasurementState.idle) return;
    
    _lastResult = null;
    _measurementProgress = 0;
    
    // Apply current machine class
    final machineClass = _selectedEquipment?.machineClass ?? _settings.defaultMachineClass;
    _vibrationService.configure(machineClass: machineClass);
    
    await _vibrationService.startMeasurement();
  }
  
  Future<MeasurementResult?> stopMeasurement() async {
    _lastResult = await _vibrationService.stopMeasurement();
    return _lastResult;
  }
  
  void resetMeasurement() {
    _vibrationService.reset();
    _lastResult = null;
    _measurementProgress = 0;
    notifyListeners();
  }
  
  Future<void> saveMeasurement({String? notes, String? imagePath}) async {
    if (_lastResult == null || _selectedPoint == null) return;
    
    final measurement = Measurement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pointId: _selectedPoint!.id,
      timestamp: DateTime.now(),
      accelerationRms: _lastResult!.accelerationRms,
      accelerationPeak: _lastResult!.accelerationPeak,
      velocityRms: _lastResult!.velocityRms,
      velocityPeak: _lastResult!.velocityPeak,
      displacementRms: _lastResult!.displacementRms,
      displacementPeak: _lastResult!.displacementPeak,
      crestFactor: _lastResult!.crestFactor,
      kurtosis: _lastResult!.kurtosis,
      isoZone: _lastResult!.isoZone,
      machineClass: _selectedEquipment?.machineClass ?? _settings.defaultMachineClass,
      spectrumData: _lastResult!.spectrum,
      waveformData: _lastResult!.waveform,
      fftSize: _settings.fftSize,
      windowFunction: _settings.windowFunction,
      sampleRate: _settings.sampleRate,
      notes: notes,
      imagePath: imagePath,
      rpm: _selectedEquipment?.nominalRpm,
    );
    
    await _storageService.saveMeasurement(measurement);
    _measurements = _storageService.getMeasurementsForPoint(_selectedPoint!.id);
    notifyListeners();
  }
  
  // ==================== Settings ====================
  
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storageService.saveSettings(newSettings);
    _applySettings();
    notifyListeners();
  }
  
  // ==================== Data Management ====================
  
  List<Measurement> getRecentMeasurements({int limit = 20}) {
    return _storageService.getRecentMeasurements(limit: limit);
  }
  
  Map<String, dynamic> getPointStatistics(String pointId) {
    return _storageService.getPointStatistics(pointId);
  }
  
  Future<void> deleteMeasurement(String id) async {
    await _storageService.deleteMeasurement(id);
    if (_selectedPoint != null) {
      _measurements = _storageService.getMeasurementsForPoint(_selectedPoint!.id);
    }
    notifyListeners();
  }
  
  // ==================== Helpers ====================
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _vibrationService.dispose();
    super.dispose();
  }
}
