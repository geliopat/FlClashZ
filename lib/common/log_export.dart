import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fl_clash/common/file_logger.dart';
import 'package:fl_clash/common/recovery_journal.dart';
import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef LogSnapshot = ({List<File> files, int pending});
typedef _LogFile = ({String path, String name});
typedef _ArchiveJob = ({
  String destination,
  List<_LogFile> files,
  String manifest,
  String? native,
  String dns,
});

/// Export only known log sources, never the application home or profile files.
Future<List<String>> exportAllLogs(File archive, {required String dnsSnapshot}) =>
    buildLogArchive(archive, sources: {
      'mihomo': fileLogger.retainedFiles,
      'zapret': zapretFileLogger.retainedFiles,
      'application': appFileLogger.retainedFiles,
      'crashes': crashFileLogger.retainedFiles,
      'recovery': recoveryJournal.retainedFiles,
    }, nativeArchive: helperClient.zapretLogArchive, dnsSnapshot: dnsSnapshot);

@visibleForTesting
Future<List<String>> buildLogArchive(
  File archive, {
  required Map<String, Future<LogSnapshot> Function()> sources,
  required Future<String> Function() nativeArchive,
  required String dnsSnapshot,
}) async {
  final files = <_LogFile>[];
  final incomplete = <String>[];
  final manifest = <String, Object?>{};
  for (final entry in sources.entries) {
    try {
      final snapshot = await entry.value();
      files.addAll(snapshot.files.map((file) =>
          (path: file.path, name: '${entry.key}/${p.basename(file.path)}')));
      manifest[entry.key] = {'files': snapshot.files.length, 'unflushed': snapshot.pending};
      if (snapshot.pending != 0) incomplete.add(entry.key);
    } catch (_) {
      manifest[entry.key] = {'unavailable': true};
      incomplete.add(entry.key);
    }
  }
  String? native;
  try {
    native = await nativeArchive();
    manifest['helper'] = {'available': true, 'scope': 'retained IPC archive'};
  } catch (_) {
    incomplete.add('helper');
    manifest['helper'] = {'unavailable': true};
  }
  manifest['dns'] = {'scope': 'current in-memory ring'};
  await compute(_writeLogArchive, (
    destination: archive.path, files: files,
    manifest: const JsonEncoder.withIndent('  ').convert({
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'sources': manifest, 'incomplete': incomplete,
    }), native: native, dns: dnsSnapshot,
  ));
  return incomplete;
}

Future<void> _writeLogArchive(_ArchiveJob job) async {
  // Use staging for the small generated entries; stream retained files from
  // their existing paths rather than collecting all contents into memory.
  final scratch = await Directory.systemTemp.createTemp('flclashz-log-index-');
  try {
    final encoder = ZipFileEncoder()..create(job.destination);
    try {
      for (final file in job.files) {
        await encoder.addFile(File(file.path), file.name);
      }
      Future<void> addText(String name, String contents) async {
        final file = File(p.join(scratch.path, p.basename(name)));
        await file.writeAsString(contents, flush: true);
        await encoder.addFile(file, name);
      }
      await addText('manifest.json', job.manifest);
      if (job.native != null) await addText('helper/service.jsonl', job.native!);
      await addText('dns/queries.json', job.dns);
    } finally {
      await encoder.close();
    }
  } finally {
    await scratch.delete(recursive: true);
  }
}
