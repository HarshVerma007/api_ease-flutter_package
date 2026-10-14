import 'dart:async';

import 'package:api_ease/api_ease.dart';
import 'package:api_ease/src/core/debounce_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A zero window de-duplicates in-flight requests only, which keeps the
  // tests free of lingering timers.
  const config = DebounceConfig(enabled: true, window: Duration.zero);

  tearDown(DebounceHandler.cancelAll);

  test('a duplicate key returns the same future', () async {
    final completer = Completer<int>();
    var calls = 0;
    Future<int> action() {
      calls++;
      return completer.future;
    }

    final first =
        DebounceHandler.execute<int>(key: 'a', action: action, config: config);
    final second =
        DebounceHandler.execute<int>(key: 'a', action: action, config: config);

    expect(identical(first, second), isTrue);
    expect(calls, 1);

    completer.complete(42);
    expect(await first, 42);
    expect(await second, 42);
  });

  test('different keys run independently', () async {
    var calls = 0;
    Future<int> action() async {
      calls++;
      return calls;
    }

    final first =
        DebounceHandler.execute<int>(key: 'a', action: action, config: config);
    final second =
        DebounceHandler.execute<int>(key: 'b', action: action, config: config);

    expect(calls, 2);
    expect(await first, isNot(equals(await second)));
  });

  test('the key is released once the request completes', () async {
    var calls = 0;
    Future<int> action() async => ++calls;

    await DebounceHandler.execute<int>(key: 'a', action: action, config: config);
    await Future<void>.delayed(Duration.zero);
    await DebounceHandler.execute<int>(key: 'a', action: action, config: config);

    expect(calls, 2);
  });

  test('the key is released when the request fails', () async {
    var calls = 0;
    Future<int> action() async {
      calls++;
      throw Exception('fail');
    }

    await expectLater(
      DebounceHandler.execute<int>(key: 'a', action: action, config: config),
      throwsException,
    );
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      DebounceHandler.execute<int>(key: 'a', action: action, config: config),
      throwsException,
    );

    expect(calls, 2);
  });

  test('cancel removes the in-flight request', () async {
    final completer = Completer<int>();
    var calls = 0;
    Future<int> action() {
      calls++;
      return completer.future;
    }

    unawaited(
      DebounceHandler.execute<int>(key: 'a', action: action, config: config),
    );
    expect(DebounceHandler.trackedCount, 1);

    DebounceHandler.cancel('a');
    expect(DebounceHandler.trackedCount, 0);

    unawaited(
      DebounceHandler.execute<int>(key: 'a', action: action, config: config),
    );
    expect(calls, 2);

    completer.complete(1);
  });

  test('cancelAll clears everything', () {
    final completer = Completer<int>();
    Future<int> action() => completer.future;

    unawaited(
      DebounceHandler.execute<int>(key: 'a', action: action, config: config),
    );
    unawaited(
      DebounceHandler.execute<int>(key: 'b', action: action, config: config),
    );
    expect(DebounceHandler.trackedCount, 2);

    DebounceHandler.cancelAll();
    expect(DebounceHandler.trackedCount, 0);

    completer.complete(1);
  });

  test('runs the action every time when disabled', () async {
    var calls = 0;
    Future<int> action() async => ++calls;
    const disabled = DebounceConfig();

    await DebounceHandler.execute<int>(
        key: 'a', action: action, config: disabled);
    await DebounceHandler.execute<int>(
        key: 'a', action: action, config: disabled);

    expect(calls, 2);
    expect(DebounceHandler.trackedCount, 0);
  });

  test('a successful request keeps absorbing calls during the window',
      () async {
    var calls = 0;
    Future<int> action() async => ++calls;
    const windowed =
        DebounceConfig(enabled: true, window: Duration(milliseconds: 200));

    final first = await DebounceHandler.execute<int>(
        key: 'a', action: action, config: windowed);
    await Future<void>.delayed(Duration.zero);
    final second = await DebounceHandler.execute<int>(
        key: 'a', action: action, config: windowed);

    expect(first, 1);
    expect(second, 1);
    expect(calls, 1);

    DebounceHandler.cancel('a'); // stops the linger timer
  });
}
