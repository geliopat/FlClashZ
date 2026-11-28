import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/file.dart';
import 'package:fl_clash/common/path.dart';
import 'package:fl_clash/features/update/core_release_manifest.dart';
import 'package:path/path.dart' as p;

final _hashPattern = RegExp(r'^[0-9a-f]{64}$');

final class CoreReleaseRef {
  final String hash;
  final CoreReleaseVersion version;
  final String? engineRevision;
  final String? hostRevision;

  CoreReleaseRef.fromManifest(CoreReleaseManifest manifest)
    : hash = manifest.hash,
      version = manifest.version,
      engineRevision = manifest.engineRevision,
      hostRevision = manifest.hostRevision;

  CoreReleaseRef._(this.hash, this.version, this.engineRevision, this.hostRevision);

  factory CoreReleaseRef.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['hash'] is! String || value['version'] is! String) {
      throw const FormatException('Invalid selected core release');
    }
    final hash = value['hash'] as String;
    if (hash.length != 64 || !_hashPattern.hasMatch(hash)) {
      throw const FormatException('Invalid selected core hash');
    }
    String? revision(String field) {
      final raw = value[field];
      if (raw == null) return null;
      if (raw is! String || raw.length != 40 ||
          !RegExp(r'^[0-9a-f]{40}$').hasMatch(raw)) {
        throw const FormatException('Invalid selected core revision');
      }
      return raw;
    }
    return CoreReleaseRef._(
      hash, CoreReleaseVersion.parse(value['version'] as String),
      revision('engineRevision'), revision('hostRevision'),
    );
  }

  Map<String, String> toJson() => {
    'hash': hash, 'version': version.value,
    'engineRevision': ?engineRevision,
    'hostRevision': ?hostRevision,
  };
}

final class CoreReleaseState {
  /// null represents the immutable bundled core, never an arbitrary path.
  final CoreReleaseRef? current;
  final CoreReleaseRef? previous;
  final bool hasPrevious;
  final bool pending;

  const CoreReleaseState({
    this.current,
    this.previous,
    this.hasPrevious = false,
    this.pending = false,
  });

  factory CoreReleaseState.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['schema'] != 1 ||
        value['hasPrevious'] is! bool || value['pending'] is! bool) {
      throw const FormatException('Invalid core selection journal');
    }
    return CoreReleaseState(
      current: value['current'] == null ? null : CoreReleaseRef.fromJson(value['current']),
      previous: value['previous'] == null ? null : CoreReleaseRef.fromJson(value['previous']),
      hasPrevious: value['hasPrevious'] as bool,
      pending: value['pending'] as bool,
    );
  }

  Map<String, Object?> toJson() => {
    'schema': 1,
    'current': current?.toJson(),
    'previous': previous?.toJson(),
    'hasPrevious': hasPrevious,
    'pending': pending,
  };
}

final class CoreReleaseActivationException implements Exception {
  final Object cause;
  final bool restored;
  final Object? rollbackError;

  const CoreReleaseActivationException(this.cause, {
    required this.restored, this.rollbackError,
  });

  @override
  String toString() => 'Core activation failed: $cause; '
      'previous core restored: $restored'
      '${rollbackError == null ? '' : '; rollback failed: $rollbackError'}';
}

/// Only the existing restart worker may call the supplied restart callback.
/// The durable file always names the last committed selection during trial;
/// a process crash or power loss cannot commit an untested candidate.
final class CoreReleaseSelectionStore {
  final Future<File> Function() _file;
  final CoreReleaseVersion? minimumVersion;
  bool _trial = false;
  bool _busy = false;
  CoreReleaseRef? _trialSelection;

  CoreReleaseSelectionStore(this._file, {this.minimumVersion});

  bool _compatible(CoreReleaseRef? release) => release == null ||
      minimumVersion == null || release.version.compareTo(minimumVersion!) >= 0;

  Future<CoreReleaseState> read() async {
    final file = await _file();
    if (!await file.exists()) return const CoreReleaseState();
    if (await file.length() > 4096) {
      throw const FormatException('Oversized core selection journal');
    }
    final state = CoreReleaseState.fromJson(jsonDecode(await file.readAsString()));
    // A newer client can replace an old standalone adapter with its own
    // compatible bundled core without deleting the old signed slot.
    if (!_compatible(state.current)) return const CoreReleaseState();
    if (!_compatible(state.previous)) {
      return CoreReleaseState(current: state.current,
          hasPrevious: state.hasPrevious, pending: state.pending);
    }
    return state;
  }

  Future<CoreReleaseRef?> selectedForLaunch() async {
    if (_trial) return _trialSelection;
    try {
      // A pending entry is an interrupted trial. Its current field still
      // points to the last committed selection, so never retry the candidate.
      return (await read()).current;
    } on FormatException {
      // Corrupt user data must not authorize an arbitrary executable.
      return null;
    }
  }

  /// A committed slot can disappear (for example, after reinstall) or fail
  /// Helper verification. Outside a trial, fall back to the previous signed
  /// slot or bundled core. During a trial only the transaction may roll back.
  Future<bool> rejectCommitted(String hash) async {
    if (_busy || _trial) return false;
    _busy = true;
    try {
      final state = await read();
      if (state.current?.hash != hash) return false;
      final previous = state.hasPrevious ? state.previous : null;
      await _write(CoreReleaseState(
        current: previous,
        hasPrevious: previous != null,
      ));
      return true;
    } finally {
      _busy = false;
    }
  }

  Future<void> _write(CoreReleaseState state) async {
    final file = await _file();
    await file.writeAsStringAtomically(jsonEncode(state.toJson()));
  }

  Future<bool> activate(
    CoreReleaseManifest manifest, {
    required String bundledVersion,
    required Future<bool> Function() restart,
    bool Function()? healthy,
  }) => _change(
    healthy: healthy,
    target: CoreReleaseRef.fromManifest(manifest),
    bundledVersion: bundledVersion,
    restart: restart,
  );

  Future<bool> restorePrevious({
    required Future<bool> Function() restart,
    bool Function()? healthy,
  }) => _change(restore: true, restart: restart, healthy: healthy);

  Future<bool> _change({
    CoreReleaseRef? target,
    String? bundledVersion,
    bool restore = false,
    required Future<bool> Function() restart,
    bool Function()? healthy,
  }) async {
    if (_busy) throw StateError('Core release activation already running');
    _busy = true;
    try {
      final state = await read();
      if (restore) {
        if (!state.hasPrevious) throw StateError('No previous core release');
        target = state.previous;
      } else {
        final next = target!;
        final current = state.current;
        final base = bundledVersion!;
        final normalized = base.startsWith('v') ? base : 'v$base';
        final firstIndependent = CoreReleaseVersion.parse('$normalized-z.1');
        if (!_compatible(next) || next.version.compareTo(firstIndependent) < 0 ||
            (current != null && next.version.compareTo(current.version) <= 0)) {
          throw StateError('Core release is not newer than the installed version');
        }
      }

      // Pending retains the last known good selection; old and new EXEs are
      // independent immutable slots, not two partially replaced files.
      await _write(CoreReleaseState(
        current: state.current, previous: state.previous,
        hasPrevious: state.hasPrevious, pending: true,
      ));
      _trialSelection = target;
      _trial = true;
      try {
        if (!await restart() || healthy?.call() == false) {
          throw StateError('Core restart did not restore the requested configuration');
        }
        await _write(CoreReleaseState(
          current: target, previous: state.current, hasPrevious: true,
        ));
        if (healthy?.call() == false) {
          throw StateError('Core crashed while committing the selected release');
        }
        return true;
      } catch (error) {
        // Override in memory even if rewriting the journal fails: pending
        // already contains the old committed selection.
        _trialSelection = state.current;
        Object? rollbackError;
        var restored = false;
        // Restore durable selection BEFORE relaunch. Even a crash during
        // rollback must not leave a newly committed unhealthy candidate selected.
        try {
          await _write(CoreReleaseState(
            current: state.current, previous: state.previous,
            hasPrevious: state.hasPrevious,
          ));
        } catch (failure) {
          rollbackError = failure;
        }
        try {
          restored = await restart() && healthy?.call() != false;
          if (!restored) rollbackError ??= StateError('Previous core did not start');
        } catch (failure) {
          rollbackError ??= failure;
        }
        throw CoreReleaseActivationException(
          error, restored: restored, rollbackError: rollbackError,
        );
      } finally {
        _trial = false;
        _trialSelection = null;
      }
    } finally {
      _busy = false;
    }
  }
}

final coreReleaseSelection = CoreReleaseSelectionStore(
  () async => File(p.join(await appPath.homeDirPath, 'core-release-selection.json')),
  minimumVersion: CoreReleaseVersion.parse(minimumIndependentCoreVersion),
);
