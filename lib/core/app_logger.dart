import 'package:logger/logger.dart';

import 'log_redactor.dart';

final appLogger = AppLogger._();

class AppLogger {
  AppLogger._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: false,
      printEmojis: false,
    ),
  );

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(LogRedactor.redact(message), error: error, stackTrace: stackTrace);
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(LogRedactor.redact(message), error: error, stackTrace: stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(LogRedactor.redact(message), error: error, stackTrace: stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(LogRedactor.redact(message), error: error, stackTrace: stackTrace);
  }
}
