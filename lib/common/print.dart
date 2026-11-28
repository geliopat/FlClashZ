import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/file_logger.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:material_ui/material_ui.dart';

String compactError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    return statusCode != null
        ? 'DioException(${error.type.name}, HTTP $statusCode)'
        : 'DioException(${error.type.name})';
  }
  return error.toString();
}

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  // Widget tests may use an in-memory sink rather than scheduling disk I/O
  // inside a fake async zone. Production always uses the application logger.
  @visibleForTesting
  void Function(Log)? applicationLogSinkForTesting;

  void log(String? text, {LogLevel logLevel = LogLevel.info}) {
    final payload = '[APP] $text';
    debugPrint(payload);
    final log = Log.app(payload).copyWith(logLevel: logLevel);
    if (Platform.isWindows) {
      // Application diagnostics are not Mihomo engine events.
      final sink = applicationLogSinkForTesting;
      if (sink != null) {
        sink(log);
      } else {
        appFileLogger.enable();
        appFileLogger.write(log);
      }
      return;
    }
    if (!globalState.isAttach) {
      fileLogger.write(log);
      return;
    }
    globalState.container.read(logsProvider.notifier).add(log);
  }
}

final commonPrint = CommonPrint();
