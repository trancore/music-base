import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SleepTimerExpiration = FutureOr<void> Function();

class SleepTimerController extends ChangeNotifier {
  SleepTimerController({
    required this.onExpired,
    this.tickInterval = const Duration(seconds: 1),
  });

  final SleepTimerExpiration onExpired;
  final Duration tickInterval;
  Timer? _ticker;
  DateTime? _deadline;

  Duration? get remaining {
    final deadline = _deadline;
    if (deadline == null) return null;
    final value = deadline.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  void setTimer(Duration? duration) {
    _ticker?.cancel();
    _ticker = null;
    _deadline = null;
    if (duration != null && duration > Duration.zero) {
      _deadline = DateTime.now().add(duration);
      _ticker = Timer.periodic(tickInterval, (_) => _tick());
    }
    notifyListeners();
  }

  void _tick() {
    if ((remaining ?? Duration.zero) <= Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      _deadline = null;
      notifyListeners();
      unawaited(Future<void>.sync(onExpired));
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
