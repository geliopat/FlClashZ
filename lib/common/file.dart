import 'dart:io';

const _replaceAttempts = 10;
const _replaceRetryDelay = Duration(milliseconds: 50);

/// The prefix mihomo's `age.DecryptBytes` tells an encrypted config by.
const _ageArmorHeader = '-----BEGIN AGE ENCRYPTED FILE-----';

extension FileExt on File {
  Future<void> safeCopy(String newPath) async {
    if (!await exists()) {
      await create(recursive: true);
      return;
    }
    final targetFile = File(newPath);
    if (!await targetFile.exists()) {
      await targetFile.create(recursive: true);
    }
    await copy(newPath);
  }

  Future<bool> get isAgeEncrypted async {
    final head = await openRead(
      0,
      _ageArmorHeader.length,
    ).expand((chunk) => chunk).toList();
    return String.fromCharCodes(head) == _ageArmorHeader;
  }

  Future<File> safeWriteAsString(String str) async {
    if (!await exists()) {
      await create(recursive: true);
    }
    return writeAsString(str);
  }

  Future<File> safeWriteAsBytes(List<int> bytes) async {
    if (!await exists()) {
      await create(recursive: true);
    }
    return writeAsBytes(bytes);
  }

  /// Each writer owns its staging directory, even across isolates or processes.
  /// Concurrent writers may replace one another, but cannot share partial data.
  Future<void> writeAsStringAtomically(String content) async {
    await parent.create(recursive: true);
    final staging = await parent.createTemp('.flclash-write-');
    final temp = File('${staging.path}${Platform.pathSeparator}value');
    try {
      await temp.writeAsString(content, flush: true);
      await temp._renameRetryingWhileHeldOpen(path);
    } finally {
      // Never remove another writer's temporary file.
      await staging.delete(recursive: true).then((_) {}, onError: (_) {});
    }
  }

  Future<void> _renameRetryingWhileHeldOpen(String target) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await rename(target);
        return;
      } on FileSystemException {
        if (attempt == _replaceAttempts) rethrow;
        await Future<void>.delayed(_replaceRetryDelay);
      }
    }
  }
}

extension FileSystemEntityExt on FileSystemEntity {
  Future<void> safeDelete({bool recursive = false}) async {
    if (!await exists()) {
      return;
    }
    await delete(recursive: recursive);
  }
}

Future<void> safeDeletePath(String path) async {
  final entity = switch (FileSystemEntity.typeSync(path)) {
    FileSystemEntityType.directory => Directory(path),
    _ => File(path),
  };
  await entity.safeDelete(recursive: true);
}
