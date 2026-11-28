import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/preferences_store.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:path/path.dart';

Future<void> clearAppData() async {
  if (await preferences.isInit || !(system.isWindows || system.isLinux)) {
    await preferences.clearPreferences();
  } else {
    // Explicitly confirmed full reset from the startup-error UI.
    await clearUnreadableFilePreferences(
      File(await appPath.sharedPreferencesPath),
      independentBackup: system.isWindows
          ? File(join(await appPath.homeDirPath, independentSettingsBackupName))
          : null,
    );
  }
  try {
    await database.close();
  } catch (error) {
    // Drift rethrows a failed open from close; that file still has to go.
    commonPrint.log(
      'close database failed: $error',
      logLevel: LogLevel.warning,
    );
  }
  await File(await appPath.databasePath).safeDelete(recursive: true);
  await Directory(await appPath.profilesPath).safeDelete(recursive: true);
}

/// [clearAppData] plus the rest of the app home, bar the instance lock and
/// the Windows disclaimer consent marker.
Future<void> resetAppData() async {
  await clearAppData();
  await fileLogger.dispose();
  final home = Directory(await appPath.homeDirPath);
  final lockPath = await appPath.lockFilePath;
  final consentPath = system.isWindows ? await appPath.disclaimerConsentPath : null;
  if (!await home.exists()) {
    return;
  }
  await for (final entity in home.list(followLinks: false)) {
    if (entity.path == lockPath || entity.path == consentPath) {
      continue;
    }
    try {
      await entity.delete(recursive: true);
    } on FileSystemException catch (error) {
      commonPrint.log(
        'reset left ${basename(entity.path)}: ${error.message}',
        logLevel: LogLevel.warning,
      );
    }
  }
}
