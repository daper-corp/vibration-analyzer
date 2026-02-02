import 'dart:async';
import 'package:flutter/foundation.dart';

/// Production-level logging utility for vibration analyzer
/// Supports:
/// - Log levels (debug, info, warning, error)
/// - Structured logging with tags
/// - Log history for debugging
/// - Conditional logging based on build mode
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();
  
  /// Log level enumeration
  static const int levelDebug = 0;
  static const int levelInfo = 1;
  static const int levelWarning = 2;
  static const int levelError = 3;
  
  /// Current log level (only logs at or above this level are shown)
  int _logLevel = kDebugMode ? levelDebug : levelInfo;
  
  /// Maximum log history entries
  static const int maxHistorySize = 500;
  
  /// Log history for debugging
  final List<LogEntry> _history = [];
  
  /// Stream controller for log events
  final _logController = StreamController<LogEntry>.broadcast();
  
  /// Get log history
  List<LogEntry> get history => List.unmodifiable(_history);
  
  /// Get log stream
  Stream<LogEntry> get logStream => _logController.stream;
  
  /// Set log level
  void setLogLevel(int level) {
    _logLevel = level;
  }
  
  /// Log debug message
  void d(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(levelDebug, tag, message, error, stackTrace);
  }
  
  /// Log info message
  void i(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(levelInfo, tag, message, error, stackTrace);
  }
  
  /// Log warning message
  void w(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(levelWarning, tag, message, error, stackTrace);
  }
  
  /// Log error message
  void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(levelError, tag, message, error, stackTrace);
  }
  
  void _log(int level, String tag, String message, dynamic error, StackTrace? stackTrace) {
    if (level < _logLevel) return;
    
    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
    
    // Add to history
    _history.add(entry);
    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    
    // Broadcast to listeners
    _logController.add(entry);
    
    // Print to console in debug mode
    if (kDebugMode) {
      final levelStr = _levelToString(level);
      final prefix = '[$levelStr][$tag]';
      debugPrint('$prefix $message');
      if (error != null) {
        debugPrint('$prefix Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$prefix StackTrace:\n$stackTrace');
      }
    }
  }
  
  String _levelToString(int level) {
    switch (level) {
      case levelDebug: return 'DEBUG';
      case levelInfo: return 'INFO';
      case levelWarning: return 'WARN';
      case levelError: return 'ERROR';
      default: return 'UNKNOWN';
    }
  }
  
  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(int minLevel) {
    return _history.where((e) => e.level >= minLevel).toList();
  }
  
  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return _history.where((e) => e.tag == tag).toList();
  }
  
  /// Clear log history
  void clearHistory() {
    _history.clear();
  }
  
  /// Export logs as string
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Vibration Analyzer Log Export ===');
    buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${_history.length}');
    buffer.writeln('');
    
    for (final entry in _history) {
      buffer.writeln(entry.toString());
    }
    
    return buffer.toString();
  }
  
  /// Dispose resources
  void dispose() {
    _logController.close();
  }
}

/// Single log entry
class LogEntry {
  final int level;
  final String tag;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });
  
  String get levelString {
    switch (level) {
      case AppLogger.levelDebug: return 'D';
      case AppLogger.levelInfo: return 'I';
      case AppLogger.levelWarning: return 'W';
      case AppLogger.levelError: return 'E';
      default: return '?';
    }
  }
  
  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    
    String result = '[$timeStr][$levelString][$tag] $message';
    
    if (error != null) {
      result += '\n  Error: $error';
    }
    
    return result;
  }
}

/// Global logger instance
final log = AppLogger();

/// Log tags for different components
class LogTags {
  static const String sensor = 'SENSOR';
  static const String fft = 'FFT';
  static const String measurement = 'MEASURE';
  static const String storage = 'STORAGE';
  static const String export = 'EXPORT';
  static const String ui = 'UI';
  static const String network = 'NETWORK';
  static const String iso = 'ISO';
  static const String bearing = 'BEARING';
}
