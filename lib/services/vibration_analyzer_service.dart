import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../utils/fft_engine.dart';
import '../constants/app_constants.dart';

/// Vibration measurement state
enum MeasurementState {
  idle,
  preparing,
  measuring,
  processing,
  complete,
  error,
}

/// Real-time vibration data
class VibrationData {
  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;
  final double accelerationMagnitude;
  final DateTime timestamp;
  
  VibrationData({
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    required this.accelerationMagnitude,
    required this.timestamp,
  });
}

/// Processed measurement result
class MeasurementResult {
  final double accelerationRms;
  final double accelerationPeak;
  final double velocityRms;
  final double velocityPeak;
  final double displacementRms;
  final double displacementPeak;
  final double crestFactor;
  final double kurtosis;
  final List<double> spectrum;
  final List<double> waveform;
  final List<double> frequencyAxis;
  final String isoZone;
  final int sampleCount;
  final double actualSampleRate;
  
  MeasurementResult({
    required this.accelerationRms,
    required this.accelerationPeak,
    required this.velocityRms,
    required this.velocityPeak,
    required this.displacementRms,
    required this.displacementPeak,
    required this.crestFactor,
    required this.kurtosis,
    required this.spectrum,
    required this.waveform,
    required this.frequencyAxis,
    required this.isoZone,
    required this.sampleCount,
    required this.actualSampleRate,
  });
}

/// Core vibration analyzer service
class VibrationAnalyzerService {
  // Configuration
  int _targetSampleRate = 200;
  int _fftSize = 2048;
  String _windowFunction = 'Hanning';
  String _averageType = 'Linear';
  int _averageCount = 4;
  String _machineClass = 'Class II';
  
  // FFT Engine
  FFTEngine? _fftEngine;
  Float64List? _windowCoefficients;
  
  // Data collection
  final List<VibrationData> _rawData = [];
  StreamSubscription? _sensorSubscription;
  DateTime? _measurementStartTime;
  
  // State
  MeasurementState _state = MeasurementState.idle;
  final _stateController = StreamController<MeasurementState>.broadcast();
  final _dataController = StreamController<VibrationData>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  
  // Anti-aliasing filter
  AntiAliasingFilter? _antiAliasingFilter;
  
  // Getters
  MeasurementState get state => _state;
  Stream<MeasurementState> get stateStream => _stateController.stream;
  Stream<VibrationData> get dataStream => _dataController.stream;
  Stream<double> get progressStream => _progressController.stream;
  
  int get targetSampleRate => _targetSampleRate;
  int get fftSize => _fftSize;
  String get windowFunction => _windowFunction;
  String get machineClass => _machineClass;
  
  /// Initialize the analyzer service
  void initialize() {
    _initFFTEngine();
  }
  
  void _initFFTEngine() {
    _fftEngine = FFTEngine(_fftSize);
    _windowCoefficients = WindowFunctions.getWindow(_windowFunction, _fftSize);
    _antiAliasingFilter = AntiAliasingFilter(
      cutoffFreq: _targetSampleRate / 2.5, // Nyquist with margin
      sampleRate: _targetSampleRate.toDouble(),
    );
  }
  
  /// Update configuration
  void configure({
    int? sampleRate,
    int? fftSize,
    String? windowFunction,
    String? averageType,
    int? averageCount,
    String? machineClass,
  }) {
    if (sampleRate != null) _targetSampleRate = sampleRate;
    if (fftSize != null) _fftSize = fftSize;
    if (windowFunction != null) _windowFunction = windowFunction;
    if (averageType != null) _averageType = averageType;
    if (averageCount != null) _averageCount = averageCount;
    if (machineClass != null) _machineClass = machineClass;
    
    _initFFTEngine();
  }
  
  /// Start measurement
  Future<void> startMeasurement() async {
    if (_state != MeasurementState.idle) return;
    
    _setState(MeasurementState.preparing);
    _rawData.clear();
    _measurementStartTime = DateTime.now();
    
    try {
      // Start sensor data collection
      _sensorSubscription = accelerometerEventStream(
        samplingPeriod: Duration(microseconds: (1000000 ~/ _targetSampleRate)),
      ).listen(_onSensorData);
      
      _setState(MeasurementState.measuring);
    } catch (e) {
      _setState(MeasurementState.error);
      debugPrint('Sensor error: $e');
    }
  }
  
  void _onSensorData(AccelerometerEvent event) {
    // For vibration analysis, we use the AC component (dynamic acceleration)
    // Remove the static gravity component from each axis
    // This approach works regardless of device orientation
    
    // Calculate magnitude of acceleration vector
    final magnitude = math.sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // The gravity-corrected magnitude is the difference from static gravity
    // This gives us the dynamic (vibration) component
    // Note: This is a simplified approach. For production, consider using
    // a high-pass filter or complementary filter for better gravity removal
    final dynamicAccel = (magnitude - AppConstants.gravity).abs();
    
    final data = VibrationData(
      accelerationX: event.x,
      accelerationY: event.y,
      accelerationZ: event.z,
      accelerationMagnitude: dynamicAccel,
      timestamp: DateTime.now(),
    );
    
    _rawData.add(data);
    _dataController.add(data);
    
    // Update progress
    final requiredSamples = _fftSize * _averageCount;
    final progress = (_rawData.length / requiredSamples).clamp(0.0, 1.0);
    _progressController.add(progress);
    
    // Auto-stop when enough samples collected
    if (_rawData.length >= requiredSamples) {
      stopMeasurement();
    }
  }
  
  /// Stop measurement and process data
  Future<MeasurementResult?> stopMeasurement() async {
    if (_state != MeasurementState.measuring) return null;
    
    await _sensorSubscription?.cancel();
    _sensorSubscription = null;
    
    _setState(MeasurementState.processing);
    
    try {
      final result = await _processData();
      _setState(MeasurementState.complete);
      return result;
    } catch (e) {
      debugPrint('Processing error: $e');
      _setState(MeasurementState.error);
      return null;
    }
  }
  
  /// Process collected data
  Future<MeasurementResult> _processData() async {
    // Extract magnitude data
    final magnitudes = _rawData.map((d) => d.accelerationMagnitude).toList();
    
    // Calculate actual sample rate
    final duration = _rawData.last.timestamp.difference(_measurementStartTime!);
    final actualSampleRate = _rawData.length / duration.inMilliseconds * 1000;
    
    // Apply anti-aliasing filter
    final filteredData = Float64List.fromList(magnitudes);
    _antiAliasingFilter?.filterArray(filteredData);
    
    // Prepare for FFT averaging
    final averager = SignalAverager(
      averageCount: _averageCount,
      averageType: _averageType,
      signalLength: _fftSize,
    );
    
    // Process blocks for averaging
    final numBlocks = filteredData.length ~/ _fftSize;
    for (int i = 0; i < numBlocks && i < _averageCount; i++) {
      final start = i * _fftSize;
      final block = Float64List.sublistView(filteredData, start, start + _fftSize);
      averager.addSignal(block);
    }
    
    // Get averaged signal
    final averagedSignal = averager.getAverage() ?? Float64List.fromList(
      filteredData.sublist(0, _fftSize)
    );
    
    // Apply window function
    final windowedSignal = Float64List(_fftSize);
    for (int i = 0; i < _fftSize; i++) {
      windowedSignal[i] = averagedSignal[i] * _windowCoefficients![i];
    }
    
    // Perform FFT
    final real = Float64List.fromList(windowedSignal);
    final imag = Float64List(_fftSize);
    _fftEngine!.transform(real, imag);
    
    // Get magnitude spectrum
    final spectrum = _fftEngine!.getMagnitude(real, imag);
    
    // Calculate frequency axis
    final freqResolution = actualSampleRate / _fftSize;
    final frequencyAxis = List<double>.generate(
      spectrum.length,
      (i) => i * freqResolution,
    );
    
    // Calculate acceleration parameters
    final accelRms = VibrationParameters.calculateRMS(averagedSignal);
    final accelPeak = VibrationParameters.calculatePeak(averagedSignal);
    final crestFactor = VibrationParameters.calculateCrestFactor(averagedSignal);
    final kurtosis = VibrationParameters.calculateKurtosis(averagedSignal);
    
    // Integrate to velocity
    final velocity = SignalIntegration.integrateToVelocity(
      averagedSignal, 
      actualSampleRate,
    );
    final velRms = VibrationParameters.calculateRMS(velocity);
    final velPeak = VibrationParameters.calculatePeak(velocity);
    
    // Integrate to displacement
    final displacement = SignalIntegration.integrateToDisplacement(
      averagedSignal, 
      actualSampleRate,
    );
    final dispRms = VibrationParameters.calculateRMS(displacement);
    final dispPeak = VibrationParameters.calculatePeak(displacement);
    
    // Determine ISO zone
    final isoZone = _determineISOZone(velRms);
    
    // Prepare waveform for display (downsample if needed)
    final waveform = _downsampleForDisplay(
      averagedSignal, 
      AppConstants.waveformDisplayPoints,
    );
    
    // Prepare spectrum for display
    final displaySpectrum = _downsampleForDisplay(
      spectrum, 
      AppConstants.spectrumDisplayPoints,
    );
    
    return MeasurementResult(
      accelerationRms: accelRms,
      accelerationPeak: accelPeak,
      velocityRms: velRms,
      velocityPeak: velPeak,
      displacementRms: dispRms,
      displacementPeak: dispPeak,
      crestFactor: crestFactor,
      kurtosis: kurtosis,
      spectrum: displaySpectrum,
      waveform: waveform,
      frequencyAxis: frequencyAxis.sublist(0, displaySpectrum.length),
      isoZone: isoZone,
      sampleCount: _rawData.length,
      actualSampleRate: actualSampleRate,
    );
  }
  
  /// Determine ISO 10816 zone based on velocity RMS
  String _determineISOZone(double velocityRms) {
    Map<String, List<double>> limits;
    
    switch (_machineClass) {
      case 'Class I':
        limits = AppConstants.isoClass1Limits;
        break;
      case 'Class II':
        limits = AppConstants.isoClass2Limits;
        break;
      case 'Class III':
        limits = AppConstants.isoClass3Limits;
        break;
      case 'Class IV':
        limits = AppConstants.isoClass4Limits;
        break;
      default:
        limits = AppConstants.isoClass2Limits;
    }
    
    for (final entry in limits.entries) {
      if (velocityRms >= entry.value[0] && velocityRms < entry.value[1]) {
        return entry.key;
      }
    }
    
    return 'D';
  }
  
  /// Downsample data for display
  List<double> _downsampleForDisplay(Float64List data, int targetLength) {
    if (data.length <= targetLength) {
      return data.toList();
    }
    
    final result = <double>[];
    final ratio = data.length / targetLength;
    
    for (int i = 0; i < targetLength; i++) {
      final start = (i * ratio).floor();
      final end = ((i + 1) * ratio).floor().clamp(start + 1, data.length);
      
      // Take max absolute value in each bin for peak preservation
      double maxVal = 0;
      for (int j = start; j < end; j++) {
        if (data[j].abs() > maxVal.abs()) {
          maxVal = data[j];
        }
      }
      result.add(maxVal);
    }
    
    return result;
  }
  
  void _setState(MeasurementState newState) {
    _state = newState;
    _stateController.add(newState);
  }
  
  /// Reset to idle state
  void reset() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _rawData.clear();
    _setState(MeasurementState.idle);
  }
  
  /// Dispose resources
  void dispose() {
    _sensorSubscription?.cancel();
    _stateController.close();
    _dataController.close();
    _progressController.close();
  }
}

/// Simulated vibration service for web testing
class SimulatedVibrationService {
  Timer? _simulationTimer;
  final _dataController = StreamController<VibrationData>.broadcast();
  final _stateController = StreamController<MeasurementState>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  
  MeasurementState _state = MeasurementState.idle;
  final List<VibrationData> _rawData = [];
  
  int _targetSampleRate = 200;
  int _fftSize = 2048;
  String _windowFunction = 'Hanning';
  // ignore: unused_field - Used in configure method for future averaging implementation
  String _averageType = 'Linear';
  int _averageCount = 4;
  String _machineClass = 'Class II';
  
  // Simulation parameters
  double _baseFrequency = 25.0; // Hz (simulated shaft frequency)
  double _amplitude = 0.5; // m/s² base amplitude
  
  Stream<VibrationData> get dataStream => _dataController.stream;
  Stream<MeasurementState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;
  MeasurementState get state => _state;
  
  int get targetSampleRate => _targetSampleRate;
  int get fftSize => _fftSize;
  String get windowFunction => _windowFunction;
  String get machineClass => _machineClass;
  
  void initialize() {}
  
  void configure({
    int? sampleRate,
    int? fftSize,
    String? windowFunction,
    String? averageType,
    int? averageCount,
    String? machineClass,
  }) {
    if (sampleRate != null) _targetSampleRate = sampleRate;
    if (fftSize != null) _fftSize = fftSize;
    if (windowFunction != null) _windowFunction = windowFunction;
    if (averageType != null) _averageType = averageType;
    if (averageCount != null) _averageCount = averageCount;
    if (machineClass != null) _machineClass = machineClass;
  }
  
  void setSimulationParams({double? frequency, double? amplitude}) {
    if (frequency != null) _baseFrequency = frequency;
    if (amplitude != null) _amplitude = amplitude;
  }
  
  Future<void> startMeasurement() async {
    if (_state != MeasurementState.idle) return;
    
    _setState(MeasurementState.preparing);
    _rawData.clear();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    _setState(MeasurementState.measuring);
    
    final random = math.Random();
    int sampleCount = 0;
    final startTime = DateTime.now();
    
    _simulationTimer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ _targetSampleRate),
      (timer) {
        final t = sampleCount / _targetSampleRate;
        
        // Generate realistic vibration signal
        // Base frequency (1x shaft speed - unbalance)
        double signal = _amplitude * math.sin(2 * math.pi * _baseFrequency * t);
        
        // 2x harmonic (misalignment)
        signal += _amplitude * 0.3 * math.sin(2 * math.pi * _baseFrequency * 2 * t);
        
        // Bearing defect frequency simulation
        signal += _amplitude * 0.15 * math.sin(2 * math.pi * _baseFrequency * 4.2 * t);
        
        // Add noise
        signal += (random.nextDouble() - 0.5) * _amplitude * 0.2;
        
        final data = VibrationData(
          accelerationX: signal * 0.7,
          accelerationY: signal * 0.5,
          accelerationZ: signal,
          accelerationMagnitude: signal,
          timestamp: startTime.add(Duration(microseconds: (t * 1000000).round())),
        );
        
        _rawData.add(data);
        _dataController.add(data);
        
        sampleCount++;
        
        final requiredSamples = _fftSize * _averageCount;
        final progress = (sampleCount / requiredSamples).clamp(0.0, 1.0);
        _progressController.add(progress);
        
        if (sampleCount >= requiredSamples) {
          stopMeasurement();
        }
      },
    );
  }
  
  Future<MeasurementResult?> stopMeasurement() async {
    if (_state != MeasurementState.measuring) return null;
    
    _simulationTimer?.cancel();
    _simulationTimer = null;
    
    _setState(MeasurementState.processing);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final result = _processSimulatedData();
    _setState(MeasurementState.complete);
    
    return result;
  }
  
  MeasurementResult _processSimulatedData() {
    final magnitudes = Float64List.fromList(
      _rawData.map((d) => d.accelerationMagnitude).toList(),
    );
    
    final actualSampleRate = _targetSampleRate.toDouble();
    
    // Calculate parameters
    final accelRms = VibrationParameters.calculateRMS(magnitudes);
    final accelPeak = VibrationParameters.calculatePeak(magnitudes);
    final crestFactor = VibrationParameters.calculateCrestFactor(magnitudes);
    final kurtosis = VibrationParameters.calculateKurtosis(magnitudes);
    
    // Simulated velocity (roughly amplitude / 2*pi*f)
    final velRms = accelRms * 1000 / (2 * math.pi * _baseFrequency);
    final velPeak = accelPeak * 1000 / (2 * math.pi * _baseFrequency);
    
    // Simulated displacement
    final dispRms = velRms * 1000 / (2 * math.pi * _baseFrequency);
    final dispPeak = velPeak * 1000 / (2 * math.pi * _baseFrequency);
    
    // Generate spectrum
    final fftEngine = FFTEngine(_fftSize);
    final window = WindowFunctions.getWindow(_windowFunction, _fftSize);
    
    final block = magnitudes.length >= _fftSize 
        ? Float64List.sublistView(magnitudes, 0, _fftSize)
        : Float64List(_fftSize);
    
    for (int i = 0; i < block.length && i < magnitudes.length; i++) {
      block[i] = magnitudes[i] * window[i];
    }
    
    final real = Float64List.fromList(block);
    final imag = Float64List(_fftSize);
    fftEngine.transform(real, imag);
    
    final spectrum = fftEngine.getMagnitude(real, imag);
    
    // Frequency axis
    final freqResolution = actualSampleRate / _fftSize;
    final frequencyAxis = List<double>.generate(
      spectrum.length,
      (i) => i * freqResolution,
    );
    
    // Determine ISO zone
    final isoZone = _determineISOZone(velRms);
    
    // Downsample for display
    final waveform = magnitudes.length > 512
        ? magnitudes.sublist(0, 512).toList()
        : magnitudes.toList();
    
    final displaySpectrum = spectrum.length > 256
        ? spectrum.sublist(0, 256).toList()
        : spectrum.toList();
    
    return MeasurementResult(
      accelerationRms: accelRms,
      accelerationPeak: accelPeak,
      velocityRms: velRms,
      velocityPeak: velPeak,
      displacementRms: dispRms,
      displacementPeak: dispPeak,
      crestFactor: crestFactor,
      kurtosis: kurtosis,
      spectrum: displaySpectrum,
      waveform: waveform,
      frequencyAxis: frequencyAxis.sublist(0, displaySpectrum.length),
      isoZone: isoZone,
      sampleCount: _rawData.length,
      actualSampleRate: actualSampleRate,
    );
  }
  
  String _determineISOZone(double velocityRms) {
    Map<String, List<double>> limits;
    
    switch (_machineClass) {
      case 'Class I':
        limits = AppConstants.isoClass1Limits;
        break;
      case 'Class II':
        limits = AppConstants.isoClass2Limits;
        break;
      case 'Class III':
        limits = AppConstants.isoClass3Limits;
        break;
      case 'Class IV':
        limits = AppConstants.isoClass4Limits;
        break;
      default:
        limits = AppConstants.isoClass2Limits;
    }
    
    for (final entry in limits.entries) {
      if (velocityRms >= entry.value[0] && velocityRms < entry.value[1]) {
        return entry.key;
      }
    }
    
    return 'D';
  }
  
  void _setState(MeasurementState newState) {
    _state = newState;
    _stateController.add(newState);
  }
  
  void reset() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _rawData.clear();
    _setState(MeasurementState.idle);
  }
  
  void dispose() {
    _simulationTimer?.cancel();
    _dataController.close();
    _stateController.close();
    _progressController.close();
  }
}
