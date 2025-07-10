import 'dart:async';

class MyScheduler {
  final Duration interval;
  final FutureOr<void> Function() onTick;

  Timer? _timer;

  MyScheduler({
    required this.interval,
    required this.onTick,
  });

  void start() {
    _timer ??= Timer.periodic(interval, (_) async {
      await onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
