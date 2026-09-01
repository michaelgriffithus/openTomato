import 'dart:async';

/// Debounces live persistence: at most one write per [minPersistInterval],
/// issued [debounce] after the last change, so a chatty sensor never writes
/// a row per second.
class HALiveFlushScheduler {
  final Duration debounce;
  final Duration minPersistInterval;
  final Future<void> Function(Set<String> growSpaceIds) persist;

  Timer? _timer;
  final Set<String> _pending = {};
  DateTime? _lastPersistAt;

  HALiveFlushScheduler({
    required this.debounce,
    required this.minPersistInterval,
    required this.persist,
  });

  void queue(Set<String> growSpaceIds, {required DateTime now}) {
    _pending.addAll(growSpaceIds);
    final last = _lastPersistAt;
    if (last != null && now.difference(last) < minPersistInterval) {
      // Too soon; the next queue() after the interval flushes everything.
      return;
    }
    _timer?.cancel();
    _timer = Timer(debounce, () async {
      final ids = Set<String>.from(_pending);
      _pending.clear();
      if (ids.isEmpty) return;
      _lastPersistAt = DateTime.now();
      await persist(ids);
    });
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _pending.clear();
    _lastPersistAt = null;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
