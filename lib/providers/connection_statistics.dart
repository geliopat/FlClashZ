import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/connection_snapshot.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core.dart';

/// A successful poll is a new time sample even when the connection counters
/// have not moved. Speed projections must be able to decay to zero.
class ConnectionStatisticsSample {
  const ConnectionStatisticsSample(this.snapshot, this.sampledAt);

  final ConnectionSnapshot snapshot;
  final DateTime sampledAt;
}

/// One demand-driven UI connection feed per provider container. The core
/// controller still owns coalescing and invalidation for explicit reads.
final connectionStatisticsProvider =
    StreamProvider.autoDispose<ConnectionStatisticsSample?>((ref) {
  final visible = ref.watch(appVisibleProvider);
  final status = ref.watch(coreStatusProvider);
  if (!visible || status != CoreStatus.connected) {
    return Stream.value(null);
  }

  final core = ref.watch(coreHandlerProvider);
  final stream = StreamController<ConnectionStatisticsSample?>();
  Timer? timer;
  var disposed = false;
  var emitted = false;
  ConnectionSnapshot? previous;

  void publish(ConnectionSnapshot? sample) {
    if (disposed || (emitted && previous == null && sample == null)) return;
    emitted = true;
    previous = sample;
    stream.add(sample == null ? null : ConnectionStatisticsSample(sample, DateTime.now()));
  }

  Future<void> poll() async {
    if (disposed) return;
    try {
      final sample = await core.getConnectionSnapshot();
      publish(sample);
    } catch (error) {
      if (!disposed) {
        if (!emitted || previous != null) {
          commonPrint.log(
            'Connection statistics unavailable: $error',
            logLevel: coreFailureLogLevel(error),
          );
        }
        publish(null);
      }
    } finally {
      // A slow response applies backpressure; no overlapping periodic read.
      if (!disposed) {
        timer = Timer(const Duration(seconds: 1), () => unawaited(poll()));
      }
    }
  }

  ref.onDispose(() {
    disposed = true;
    timer?.cancel();
    unawaited(stream.close());
  });
  stream.onListen = () => unawaited(poll());
  return stream.stream;
});
