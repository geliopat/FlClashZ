import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('preferences_store');
    path = join(dir.path, 'shared_preferences.json');
  });

  tearDown(() => dir.delete(recursive: true));

  AtomicFilePreferencesStore openStore() {
    return AtomicFilePreferencesStore(Future.value(path));
  }

  Object? readFile() => json.decode(File(path).readAsStringSync());

  List<String> dirEntries() {
    return dir.listSync().map((entity) => basename(entity.path)).toList();
  }

  test('reads the file the upstream store writes', () async {
    File(path).writeAsStringSync(
      json.encode({
        'flutter.config': '{"a":1}',
        'flutter.version': 1,
        'flutter.flag': true,
        'flutter.ratio': 0.5,
        'flutter.list': ['a', 'b'],
        'other': 'kept',
      }),
    );

    expect(await openStore().getAll(), {
      'flutter.config': '{"a":1}',
      'flutter.version': 1,
      'flutter.flag': true,
      'flutter.ratio': 0.5,
      'flutter.list': ['a', 'b'],
    });
  });

  test('a missing or empty file reads as empty', () async {
    expect(await openStore().getAll(), isEmpty);

    File(path).writeAsStringSync('');

    expect(await openStore().getAll(), isEmpty);
  });

  test('a torn file fails to load until it is readable again', () async {
    File(path).writeAsStringSync('{"flutter.config": "{');
    final store = openStore();

    await expectLater(store.getAll(), throwsFormatException);

    File(path).writeAsStringSync(json.encode({'flutter.config': '{}'}));

    expect(await store.getAll(), {'flutter.config': '{}'});
  });

  test('writes keep keys outside the prefix', () async {
    File(path).writeAsStringSync(json.encode({'other': 'kept'}));
    final store = openStore();

    expect(await store.setValue('String', 'flutter.config', 'x'), isTrue);
    expect(await store.remove('flutter.missing'), isTrue);
    expect(readFile(), {'other': 'kept', 'flutter.config': 'x'});

    expect(await store.clear(), isTrue);
    expect(readFile(), {'other': 'kept'});
  });

  test('parameters filter by prefix and allow list', () async {
    final store = openStore();
    await store.setValue('String', 'flutter.a', 'a');
    await store.setValue('String', 'flutter.b', 'b');
    await store.setValue('String', 'other.c', 'c');

    expect(
      await store.getAllWithParameters(
        GetAllParameters(
          filter: PreferencesFilter(
            prefix: 'flutter.',
            allowList: {'flutter.a', 'other.c'},
          ),
        ),
      ),
      {'flutter.a': 'a'},
    );

    await store.clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: 'other.')),
    );
    expect(readFile(), {'flutter.a': 'a', 'flutter.b': 'b'});
  });

  test('overlapping writes all land and leave no temp file', () async {
    final store = openStore();

    final results = await Future.wait([
      for (var i = 0; i < 50; i++) store.setValue('Int', 'flutter.k$i', i),
    ]);

    expect(results, everyElement(isTrue));
    expect(readFile(), {for (var i = 0; i < 50; i++) 'flutter.k$i': i});
    expect(dirEntries(), ['shared_preferences.json']);
  });

  test('invalid mutation leaves the previous file', () async {
    File(path).writeAsStringSync(json.encode({'flutter.config': 'old'}));
    final store = openStore();
    expect(await store.setValue('String', 'flutter.config', {'invalid': true}), isFalse);
    expect(readFile(), {'flutter.config': 'old'});
  });

  test('a save that cannot replace the file removes its temp file', () async {
    Directory(path).createSync();
    File(join(path, 'occupied')).createSync();

    expect(
      await openStore().setValue('String', 'flutter.config', 'new'),
      isFalse,
    );
    expect(dirEntries(), ['shared_preferences.json']);
  });

  test('failed mutation is not committed by a later successful save', () async {
    final store = openStore();
    expect(await store.setValue('String', 'flutter.original', 'keep'), isTrue);
    // Current writer uses unique staging directories, not a PID temp name.
    // Force rename failure by occupying the actual destination after load.
    final previous = File(path).renameSync('$path.original');
    final obstruction = Directory(path)..createSync();
    File(join(path, 'occupied')).createSync();
    expect(await store.setValue('String', 'flutter.failed', 'discard'), isFalse);
    await obstruction.delete(recursive: true);
    previous.renameSync(path);
    expect(await store.setValue('String', 'flutter.next', 'ok'), isTrue);
    expect(readFile(), {'flutter.original': 'keep', 'flutter.next': 'ok'});
  });

  test('full recovery restores unrelated preferences and retains corrupt evidence', () async {
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    await store.setValue('String', 'flutter.config', '{"profile":42}');
    await store.setValue('Bool', 'flutter.zapret.watchdog', false);
    await store.setValue('String', 'other.unknown', 'keep');
    const damaged = '{"flutter.config":';
    await File(path).writeAsString(damaged, flush: true);
    final reopened = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await reopened.getAll(), {
      'flutter.config': '{"profile":42}',
      'flutter.zapret.watchdog': false,
    });
    expect(readFile(), containsPair('other.unknown', 'keep'));
    final evidence = dir.listSync().whereType<File>().singleWhere(
      (file) => file.path.contains('.corrupt-'),
    );
    expect(await evidence.readAsString(), damaged);
  });

  test('valid JSON with an invalid preference type recovers full backup', () async {
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await store.setValue('Bool', 'flutter.enabled', false), isTrue);
    await File(path).writeAsString('{"flutter.enabled":{"bad":true}}', flush: true);
    final reopened = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await reopened.getAll(), {'flutter.enabled': false});
  });

  test('empty damaged primary without backup cannot be silently overwritten', () async {
    await File(path).writeAsString('');
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    await expectLater(store.getAll(), throwsFormatException);
    expect(await store.setValue('Bool', 'flutter.enabled', true), isFalse);
    expect(await File(path).readAsString(), isEmpty);
  });

  test('queued list writes and returned lists do not alias the store', () async {
    final store = openStore();
    final value = ['a'];
    final write = store.setValue('StringList', 'flutter.list', value);
    value.add('late');
    expect(await write, isTrue);
    final first = await store.getAll();
    (first['flutter.list'] as List).add('returned');
    expect(await store.getAll(), {'flutter.list': ['a']});
    expect(readFile(), {'flutter.list': ['a']});
  });

  test('explicit clear updates backup and never resurrects cleared settings', () async {
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    await store.setValue('Int', 'flutter.version', 42);
    expect(await store.clear(), isTrue);
    await File(path).delete();
    final reopened = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await reopened.getAll(), isEmpty);
  });

  test('clear cannot commit while the recovery destination is blocked', () async {
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await store.setValue('Int', 'flutter.version', 42), isTrue);
    final backupPath = '$path.last-good';
    final backup = await File(backupPath).rename('$backupPath.saved');
    final obstruction = await Directory(backupPath).create();
    await File(join(obstruction.path, 'occupied')).create();
    expect(await store.clear(), isFalse);
    expect(await store.getAll(), {'flutter.version': 42});
    expect(readFile(), {'flutter.version': 42});
    await obstruction.delete(recursive: true);
    await backup.rename(backupPath);
    expect(await store.clear(), isTrue);
    await File(path).delete();
    final reopened = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await reopened.getAll(), isEmpty);
  });

  test('failed primary clear restores the previous recovery contents', () async {
    final store = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await store.setValue('Int', 'flutter.version', 42), isTrue);
    await File(path).delete();
    final obstruction = await Directory(path).create();
    await File(join(obstruction.path, 'occupied')).create();
    expect(await store.clear(), isFalse);
    expect(jsonDecode(await File('$path.last-good').readAsString()), {'flutter.version': 42});
    expect(await store.getAll(), {'flutter.version': 42});
    await obstruction.delete(recursive: true);
    final reopened = AtomicFilePreferencesStore(Future.value(path), enableRecovery: true);
    expect(await reopened.getAll(), {'flutter.version': 42});
  });

  test('backs SharedPreferences', () async {
    addTearDown(SharedPreferences.resetStatic);
    SharedPreferencesStorePlatform.instance = openStore();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('config', '{}');
    await preferences.setStringList('list', ['a']);

    expect(readFile(), {
      'flutter.config': '{}',
      'flutter.list': ['a'],
    });

    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = openStore();
    final reopened = await SharedPreferences.getInstance();

    expect(reopened.getString('config'), '{}');
    expect(reopened.getStringList('list'), ['a']);
  });
}
