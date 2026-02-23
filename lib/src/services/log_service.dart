import 'dart:collection';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

  File? _logFile;
  bool _isFileInitStarted = false;

  Future<void> ensureFileInitialized() async {
    if (_logFile != null || _isFileInitStarted) return;
    _isFileInitStarted = true;
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/debug_log_utf8.txt');
      i("LogService: File logging initialized at ${_logFile?.path}");
    } catch (e) {
      debugPrint("Failed to initialize file logging: $e");
    }
  }

  Future<void> _writeToFile(String text) async {
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$text\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      debugPrint("Failed to write to log file: $e");
    }
  }

  static String _redact(dynamic message) {
    if (message == null) return "null";
    String msg = message.toString();
    
    // Simple regex redaction for common patterns
    // varying case for keys, capturing values
    final sensitiveKeys = ['password', 'token', 'secret', 'key', 'authorization', 'cookie'];
    
    for (var key in sensitiveKeys) {
      // Regex looking for key followed by : or = and some value
      // This is a basic implementation. For structured objects (Maps), we should traverse.
      // But message here is dynamic, often a string.
      // If message is Map/List, we should traverse before toString.
       if (message is Map) {
         return _redactMap(message).toString();
       } else if (message is List) {
         return message.map((e) => _redact(e)).toList().toString();
       }
    }
    return msg;
  }

  static dynamic _redactMap(Map map) {
    final sensitiveKeys = ['password', 'token', 'secret', 'key', 'authorization', 'cookie'];
    Map newMap = {};
    map.forEach((key, value) {
      if (key is String && sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        newMap[key] = '[REDACTED]';
      } else if (value is Map) {
         newMap[key] = _redactMap(value);
      } else if (value is List) {
         newMap[key] = value.map((e) => _redact(e)).toList();
      } else {
        newMap[key] = value;
      }
    });
    return newMap;
  }

  // Wrapper to handle dynamic input
  static dynamic _sanitize(dynamic message) {
     if (message is Map) return _redactMap(message);
     if (message is List) return message.map((e) => _sanitize(e)).toList();
     return message; 
     // Note: If it's a string containing secrets, regex would be needed.
     // For now, assuming structural logging for sensitive data.
  }

  void _addToBuffer(Level level, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final now = DateTime.now();
    final logRecord = LogRecord(
      level: level,
      message: message.toString(), 
      error: error,
      stackTrace: stackTrace,
      timestamp: now,
    );

    if (_logBuffer.length >= _bufferSize) {
      _logBuffer.removeFirst();
    }
    _logBuffer.add(logRecord);
    
    // Write to file as well
    _writeToFile(logRecord.toString());
  }

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    _instance._logger.d(sanitized, error, stackTrace);
    _instance._addToBuffer(Level.debug, sanitized, error, stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    _instance._logger.i(sanitized, error, stackTrace);
    _instance._addToBuffer(Level.info, sanitized, error, stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    _instance._logger.w(sanitized, error, stackTrace);
    _instance._addToBuffer(Level.warning, sanitized, error, stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    _instance._logger.e(sanitized, error, stackTrace);
    _instance._addToBuffer(Level.error, sanitized, error, stackTrace);
  }
  
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final sanitized = _sanitize(message);
    _instance._logger.v(sanitized, error, stackTrace);
    _instance._addToBuffer(Level.verbose, sanitized, error, stackTrace);
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
