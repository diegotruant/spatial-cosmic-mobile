import 'dart:collection';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() {
    return _instance;
  }

  late Logger _logger;
  
  // RingBuffer to store recent logs for in-app display
  // Using ListQueue for efficient add/remove
  final int _bufferSize = 100;
  final ListQueue<LogRecord> _logBuffer = ListQueue<LogRecord>();

  List<LogRecord> get logs => _logBuffer.toList();

  LogService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, 
        errorMethodCount: 8, 
        lineLength: 120, 
        colors: true, 
        printEmojis: true, 
        printTime: true,
      ),
      // Only log to console in debug mode or if configured
      level: kReleaseMode ? Level.info : Level.debug,
    );
  }

  void _addToBuffer(Level level, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_logBuffer.length >= _bufferSize) {
      _logBuffer.removeFirst();
    }
    _logBuffer.add(LogRecord(
      level: level,
      message: message.toString(),
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.d(message, error, stackTrace);
    _instance._addToBuffer(Level.debug, message, error, stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.i(message, error, stackTrace);
    _instance._addToBuffer(Level.info, message, error, stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.w(message, error, stackTrace);
    _instance._addToBuffer(Level.warning, message, error, stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.e(message, error, stackTrace);
    _instance._addToBuffer(Level.error, message, error, stackTrace);
  }
  
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _instance._logger.v(message, error, stackTrace);
    _instance._addToBuffer(Level.verbose, message, error, stackTrace);
  }
}

class LogRecord {
  final Level level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogRecord({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${level.name}] $message';
  }
}
