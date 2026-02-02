import 'dart:math' as math;
import 'dart:typed_data';

/// High-performance FFT Engine with windowing and signal processing
/// Implements Cooley-Tukey radix-2 FFT algorithm
class FFTEngine {
  final int size;
  late final Float64List _cosTable;
  late final Float64List _sinTable;
  late final Int32List _bitReversalTable;
  
  FFTEngine(this.size) {
    if (!_isPowerOfTwo(size)) {
      throw ArgumentError('FFT size must be a power of 2');
    }
    _initTables();
  }
  
  bool _isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;
  
  void _initTables() {
    // Pre-compute twiddle factors
    _cosTable = Float64List(size ~/ 2);
    _sinTable = Float64List(size ~/ 2);
    for (int i = 0; i < size ~/ 2; i++) {
      final angle = -2 * math.pi * i / size;
      _cosTable[i] = math.cos(angle);
      _sinTable[i] = math.sin(angle);
    }
    
    // Pre-compute bit reversal indices
    _bitReversalTable = Int32List(size);
    final bits = _log2(size);
    for (int i = 0; i < size; i++) {
      _bitReversalTable[i] = _reverseBits(i, bits);
    }
  }
  
  int _log2(int n) {
    int result = 0;
    while ((1 << result) < n) {
      result++;
    }
    return result;
  }
  
  int _reverseBits(int x, int bits) {
    int result = 0;
    for (int i = 0; i < bits; i++) {
      result = (result << 1) | (x & 1);
      x >>= 1;
    }
    return result;
  }
  
  /// Perform in-place FFT
  /// real and imag arrays are modified in place
  void transform(Float64List real, Float64List imag) {
    if (real.length != size || imag.length != size) {
      throw ArgumentError('Input arrays must match FFT size');
    }
    
    // Bit-reversal permutation
    for (int i = 0; i < size; i++) {
      final j = _bitReversalTable[i];
      if (i < j) {
        // Swap
        final tempR = real[i];
        final tempI = imag[i];
        real[i] = real[j];
        imag[i] = imag[j];
        real[j] = tempR;
        imag[j] = tempI;
      }
    }
    
    // Cooley-Tukey iterative FFT
    for (int len = 2; len <= size; len <<= 1) {
      final halfLen = len >> 1;
      final tableStep = size ~/ len;
      
      for (int i = 0; i < size; i += len) {
        int k = 0;
        for (int j = i; j < i + halfLen; j++) {
          final cos = _cosTable[k];
          final sin = _sinTable[k];
          k += tableStep;
          
          final evenR = real[j];
          final evenI = imag[j];
          final oddR = real[j + halfLen];
          final oddI = imag[j + halfLen];
          
          final tR = cos * oddR - sin * oddI;
          final tI = sin * oddR + cos * oddI;
          
          real[j] = evenR + tR;
          imag[j] = evenI + tI;
          real[j + halfLen] = evenR - tR;
          imag[j + halfLen] = evenI - tI;
        }
      }
    }
  }
  
  /// Compute magnitude spectrum from FFT result
  Float64List getMagnitude(Float64List real, Float64List imag) {
    final magnitude = Float64List(size ~/ 2);
    for (int i = 0; i < size ~/ 2; i++) {
      magnitude[i] = math.sqrt(real[i] * real[i] + imag[i] * imag[i]) * 2 / size;
    }
    return magnitude;
  }
  
  /// Compute power spectrum (dB)
  Float64List getPowerSpectrum(Float64List real, Float64List imag, {double reference = 1e-12}) {
    final power = Float64List(size ~/ 2);
    for (int i = 0; i < size ~/ 2; i++) {
      final mag = real[i] * real[i] + imag[i] * imag[i];
      power[i] = 10 * math.log(mag / reference) / math.ln10;
    }
    return power;
  }
}

/// Window functions for FFT preprocessing
class WindowFunctions {
  /// Apply Hanning (Hann) window
  static Float64List hanning(int size) {
    final window = Float64List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 0.5 * (1 - math.cos(2 * math.pi * i / (size - 1)));
    }
    return window;
  }
  
  /// Apply Hamming window
  static Float64List hamming(int size) {
    final window = Float64List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 0.54 - 0.46 * math.cos(2 * math.pi * i / (size - 1));
    }
    return window;
  }
  
  /// Apply Flat-top window (best for amplitude accuracy)
  static Float64List flatTop(int size) {
    final window = Float64List(size);
    const a0 = 0.21557895;
    const a1 = 0.41663158;
    const a2 = 0.277263158;
    const a3 = 0.083578947;
    const a4 = 0.006947368;
    
    for (int i = 0; i < size; i++) {
      final x = 2 * math.pi * i / (size - 1);
      window[i] = a0 - a1 * math.cos(x) + a2 * math.cos(2 * x) 
                     - a3 * math.cos(3 * x) + a4 * math.cos(4 * x);
    }
    return window;
  }
  
  /// Rectangular window (no windowing)
  static Float64List rectangular(int size) {
    final window = Float64List(size);
    for (int i = 0; i < size; i++) {
      window[i] = 1.0;
    }
    return window;
  }
  
  /// Get window function by name
  static Float64List getWindow(String name, int size) {
    switch (name) {
      case 'Hanning':
        return hanning(size);
      case 'Hamming':
        return hamming(size);
      case 'Flat-Top':
        return flatTop(size);
      case 'Rectangular':
      default:
        return rectangular(size);
    }
  }
  
  /// Window amplitude correction factors
  static double getAmplitudeCorrectionFactor(String name) {
    switch (name) {
      case 'Hanning':
        return 2.0;
      case 'Hamming':
        return 1.85;
      case 'Flat-Top':
        return 4.18;
      case 'Rectangular':
      default:
        return 1.0;
    }
  }
}

/// Anti-aliasing filter (simple low-pass IIR filter)
class AntiAliasingFilter {
  final double cutoffFreq;
  final double sampleRate;
  late final double _alpha;
  double _prevOutput = 0;
  
  AntiAliasingFilter({required this.cutoffFreq, required this.sampleRate}) {
    // Calculate filter coefficient
    final rc = 1.0 / (2 * math.pi * cutoffFreq);
    final dt = 1.0 / sampleRate;
    _alpha = dt / (rc + dt);
  }
  
  /// Apply filter to single sample
  double filter(double input) {
    _prevOutput = _prevOutput + _alpha * (input - _prevOutput);
    return _prevOutput;
  }
  
  /// Apply filter to array
  Float64List filterArray(Float64List input) {
    final output = Float64List(input.length);
    _prevOutput = input[0];
    for (int i = 0; i < input.length; i++) {
      _prevOutput = _prevOutput + _alpha * (input[i] - _prevOutput);
      output[i] = _prevOutput;
    }
    return output;
  }
  
  /// Reset filter state
  void reset() {
    _prevOutput = 0;
  }
}

/// Signal averager for noise reduction
class SignalAverager {
  final int averageCount;
  final String averageType; // 'Linear' or 'Exponential'
  final int signalLength;
  
  final List<Float64List> _buffer = [];
  Float64List? _exponentialAverage;
  int _currentCount = 0;
  
  SignalAverager({
    required this.averageCount,
    required this.averageType,
    required this.signalLength,
  });
  
  /// Add new signal to averager
  void addSignal(Float64List signal) {
    if (signal.length != signalLength) {
      throw ArgumentError('Signal length must match configured length');
    }
    
    if (averageType == 'Linear') {
      _buffer.add(Float64List.fromList(signal));
      if (_buffer.length > averageCount) {
        _buffer.removeAt(0);
      }
    } else {
      // Exponential averaging
      if (_exponentialAverage == null) {
        _exponentialAverage = Float64List.fromList(signal);
      } else {
        final alpha = 2.0 / (averageCount + 1);
        for (int i = 0; i < signalLength; i++) {
          _exponentialAverage![i] = alpha * signal[i] + (1 - alpha) * _exponentialAverage![i];
        }
      }
    }
    _currentCount++;
  }
  
  /// Get averaged signal
  Float64List? getAverage() {
    if (averageType == 'Linear') {
      if (_buffer.isEmpty) return null;
      
      final result = Float64List(signalLength);
      for (final signal in _buffer) {
        for (int i = 0; i < signalLength; i++) {
          result[i] += signal[i];
        }
      }
      for (int i = 0; i < signalLength; i++) {
        result[i] /= _buffer.length;
      }
      return result;
    } else {
      return _exponentialAverage;
    }
  }
  
  /// Check if averaging is complete
  bool get isComplete => _currentCount >= averageCount;
  
  /// Get current progress
  int get currentCount => _currentCount.clamp(0, averageCount);
  
  /// Reset averager
  void reset() {
    _buffer.clear();
    _exponentialAverage = null;
    _currentCount = 0;
  }
}

/// Integration utilities for velocity and displacement calculation
/// 
/// Note on integration accuracy:
/// - Acceleration → Velocity: Single integration
/// - Acceleration → Displacement: Double integration
/// Both processes use high-pass filtering to remove DC drift
/// which is inherent in numerical integration.
/// 
/// For production use, frequency-domain integration is more accurate
/// but this time-domain approach is sufficient for industrial diagnostics.
class SignalIntegration {
  /// Integrate acceleration to velocity
  /// Input: acceleration in m/s², Output: velocity in mm/s
  /// Uses trapezoidal integration with DC removal and drift compensation
  static Float64List integrateToVelocity(Float64List acceleration, double sampleRate) {
    final dt = 1.0 / sampleRate;
    final velocity = Float64List(acceleration.length);
    
    // Remove DC offset (mean) - critical for integration stability
    double mean = 0;
    for (final a in acceleration) {
      mean += a;
    }
    mean /= acceleration.length;
    
    // Trapezoidal integration with DC removal
    // Using trapezoidal rule: v[i] = v[i-1] + (a[i-1] + a[i]) * dt / 2
    double sum = 0;
    double prevAccel = acceleration[0] - mean;
    for (int i = 0; i < acceleration.length; i++) {
      final currAccel = acceleration[i] - mean;
      if (i > 0) {
        sum += (prevAccel + currAccel) * dt / 2;
      }
      velocity[i] = sum * 1000; // Convert m/s to mm/s
      prevAccel = currAccel;
    }
    
    // High-pass filter to remove integration drift (2 Hz cutoff for machinery)
    _highPassFilter(velocity, sampleRate, 2.0);
    
    // Remove remaining DC offset after filtering
    double velMean = 0;
    for (final v in velocity) {
      velMean += v;
    }
    velMean /= velocity.length;
    for (int i = 0; i < velocity.length; i++) {
      velocity[i] -= velMean;
    }
    
    return velocity;
  }
  
  /// Double integrate acceleration to displacement
  /// Input: acceleration in m/s², Output: displacement in μm
  /// WARNING: Double integration accumulates errors - use with caution
  static Float64List integrateToDisplacement(Float64List acceleration, double sampleRate) {
    // First integration: acceleration -> velocity (in mm/s)
    final velocity = integrateToVelocity(acceleration, sampleRate);
    
    // Second integration: velocity -> displacement
    final dt = 1.0 / sampleRate;
    final displacement = Float64List(velocity.length);
    
    // Trapezoidal integration for velocity -> displacement
    double sum = 0;
    double prevVel = velocity[0];
    for (int i = 0; i < velocity.length; i++) {
      if (i > 0) {
        sum += (prevVel + velocity[i]) * dt / 2;
      }
      displacement[i] = sum * 1000; // Convert mm to μm
      prevVel = velocity[i];
    }
    
    // High-pass filter to remove drift
    _highPassFilter(displacement, sampleRate, 2.0);
    
    // Remove remaining DC offset
    double dispMean = 0;
    for (final d in displacement) {
      dispMean += d;
    }
    dispMean /= displacement.length;
    for (int i = 0; i < displacement.length; i++) {
      displacement[i] -= dispMean;
    }
    
    return displacement;
  }
  
  /// Simple high-pass filter (first-order Butterworth)
  static void _highPassFilter(Float64List signal, double sampleRate, double cutoff) {
    final rc = 1.0 / (2 * math.pi * cutoff);
    final dt = 1.0 / sampleRate;
    final alpha = rc / (rc + dt);
    
    double prevInput = signal[0];
    double prevOutput = signal[0];
    
    for (int i = 1; i < signal.length; i++) {
      final output = alpha * (prevOutput + signal[i] - prevInput);
      prevInput = signal[i];
      prevOutput = output;
      signal[i] = output;
    }
  }
}

/// Vibration parameter calculations
class VibrationParameters {
  /// Calculate RMS (Root Mean Square)
  static double calculateRMS(Float64List signal) {
    double sum = 0;
    for (final s in signal) {
      sum += s * s;
    }
    return math.sqrt(sum / signal.length);
  }
  
  /// Calculate Peak value
  static double calculatePeak(Float64List signal) {
    double maxVal = 0;
    for (final s in signal) {
      final absVal = s.abs();
      if (absVal > maxVal) maxVal = absVal;
    }
    return maxVal;
  }
  
  /// Calculate Peak-to-Peak value
  static double calculatePeakToPeak(Float64List signal) {
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (final s in signal) {
      if (s < minVal) minVal = s;
      if (s > maxVal) maxVal = s;
    }
    return maxVal - minVal;
  }
  
  /// Calculate Crest Factor (Peak / RMS)
  static double calculateCrestFactor(Float64List signal) {
    final peak = calculatePeak(signal);
    final rms = calculateRMS(signal);
    return rms > 0 ? peak / rms : 0;
  }
  
  /// Calculate Kurtosis (indicator of impulsive signals)
  static double calculateKurtosis(Float64List signal) {
    final n = signal.length;
    if (n < 4) return 0;
    
    double mean = 0;
    for (final s in signal) {
      mean += s;
    }
    mean /= n;
    
    double m2 = 0, m4 = 0;
    for (final s in signal) {
      final d = s - mean;
      m2 += d * d;
      m4 += d * d * d * d;
    }
    m2 /= n;
    m4 /= n;
    
    return m2 > 0 ? m4 / (m2 * m2) - 3 : 0;
  }
}
