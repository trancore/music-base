import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:music_base/domain/playback/sleep_timer.dart';

void main() {
  test('expires and invokes the callback', () async {
    final expired = Completer<void>();
    final timer = SleepTimerController(
      onExpired: expired.complete,
      tickInterval: const Duration(milliseconds: 10),
    );
    addTearDown(timer.dispose);

    timer.setTimer(const Duration(milliseconds: 20));
    await expired.future.timeout(const Duration(seconds: 1));

    expect(timer.remaining, isNull);
  });

  test('can cancel an active timer', () async {
    var expired = false;
    final timer = SleepTimerController(
      onExpired: () => expired = true,
      tickInterval: const Duration(milliseconds: 10),
    );
    addTearDown(timer.dispose);

    timer.setTimer(const Duration(milliseconds: 30));
    expect(timer.remaining, isNotNull);
    timer.setTimer(null);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(timer.remaining, isNull);
    expect(expired, isFalse);
  });
}
