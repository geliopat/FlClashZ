import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// A single immutable sample shared by the visible connection consumers.
class ConnectionSnapshot {
  ConnectionSnapshot(List<TrackerInfo> connections)
    : connections = List.unmodifiable(connections),
      tcp = connections.where((c) => c.metadata.network.toLowerCase() == 'tcp').length,
      udp = connections.where((c) => c.metadata.network.toLowerCase() == 'udp').length;

  final List<TrackerInfo> connections;
  final int tcp;
  final int udp;
  int get count => connections.length;

  /// Shared, lazy dashboard ordering; never mutate the authoritative list.
  late final List<TrackerInfo> newestFirst = List.unmodifiable(
    [...connections]..sort((a, b) => b.start.compareTo(a.start)),
  );
}

/// Coalesce concurrent reads and reuse a recent sample. Never publish a
/// sample from before a core restart, connection close or explicit reset.
class ConnectionSnapshotReader {
  ConnectionSnapshotReader(
    this._read, {
    Duration maxAge = const Duration(milliseconds: 900),
    Duration Function()? elapsed,
  }) : _maxAge = maxAge,
       _elapsed = elapsed ?? _monotonicClock();

  final Future<List<TrackerInfo>> Function() _read;
  final Duration _maxAge;
  final Duration Function() _elapsed;
  ConnectionSnapshot? _cached;
  Duration? _readAt;
  Future<ConnectionSnapshot>? _pending;
  int _generation = 0;

  Future<ConnectionSnapshot> read() {
    final pending = _pending;
    if (pending != null) return pending;
    final cached = _cached;
    final at = _readAt;
    if (cached != null && at != null && _elapsed() - at < _maxAge) {
      return Future.value(cached);
    }
    final generation = _generation;
    late final Future<ConnectionSnapshot> operation;
    operation = Future.sync(_read).then((items) {
      if (generation != _generation) {
        throw StateError('Connection snapshot invalidated');
      }
      final previous = _cached;
      final snapshot = previous != null && listEquals(previous.connections, items)
          ? previous
          : ConnectionSnapshot(items);
      _cached = snapshot;
      _readAt = _elapsed();
      return snapshot;
    }).whenComplete(() {
      if (identical(_pending, operation)) _pending = null;
    });
    return _pending = operation;
  }

  void invalidate() {
    _generation++;
    _cached = null;
    _readAt = null;
    _pending = null;
  }
}

Duration Function() _monotonicClock() {
  final clock = Stopwatch()..start();
  return () => clock.elapsed;
}
