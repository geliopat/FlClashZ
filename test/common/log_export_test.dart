import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:fl_clash/common/log_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('combined archive preserves component paths and reports missing Helper', () async {
    final root = await Directory.systemTemp.createTemp('combined-log-test-');
    addTearDown(() => root.delete(recursive: true));
    final mihomo = await File(p.join(root.path, 'mihomo.log')).writeAsString('mihomo');
    final zapret = await File(p.join(root.path, 'zapret.log')).writeAsString('zapret');
    final file = File(p.join(root.path, 'logs.zip'));
    final incomplete = await buildLogArchive(file, sources: {
      'mihomo': () async => (files: [mihomo], pending: 0),
      'zapret': () async => (files: [zapret], pending: 1),
    }, nativeArchive: () async => throw StateError('offline'), dnsSnapshot: '[]');
    expect(incomplete, ['zapret', 'helper']);
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    expect(archive.files.map((entry) => entry.name), containsAll([
      'mihomo/mihomo.log', 'zapret/zapret.log', 'dns/queries.json', 'manifest.json',
    ]));
    expect(archive.files.map((entry) => entry.name), isNot(contains('helper/service.jsonl')));
    final manifest = archive.files.singleWhere((entry) => entry.name == 'manifest.json');
    expect(jsonDecode(utf8.decode(manifest.content as List<int>))['incomplete'], incomplete);
  });
}
