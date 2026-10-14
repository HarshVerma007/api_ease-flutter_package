import 'package:api_ease/api_ease.dart';
import 'package:api_ease/src/core/retry_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fast = Duration(milliseconds: 1);

  group('RetryHandler.execute', () {
    test('does not retry when maxAttempts is 0', () async {
      var calls = 0;

      await expectLater(
        RetryHandler.execute<String>(
          config: const RetryConfig(initialDelay: fast),
          action: () async {
            calls++;
            throw Exception('fail');
          },
        ),
        throwsException,
      );

      expect(calls, 1);
    });

    test('retries up to maxAttempts times', () async {
      var calls = 0;

      await expectLater(
        RetryHandler.execute<String>(
          config: const RetryConfig(maxAttempts: 3, initialDelay: fast),
          action: () async {
            calls++;
            throw Exception('fail');
          },
        ),
        throwsException,
      );

      expect(calls, 4); // 1 initial try + 3 retries
    });

    test('stops retrying when retryWhen returns false', () async {
      var calls = 0;

      await expectLater(
        RetryHandler.execute<String>(
          config: RetryConfig(
            maxAttempts: 5,
            initialDelay: fast,
            retryWhen: (error, attempt) => false,
          ),
          action: () async {
            calls++;
            throw Exception('fail');
          },
        ),
        throwsException,
      );

      expect(calls, 1);
    });

    test('per-call retryWhen overrides the config one', () async {
      var calls = 0;

      await expectLater(
        RetryHandler.execute<String>(
          config: RetryConfig(
            maxAttempts: 5,
            initialDelay: fast,
            retryWhen: (error, attempt) => true,
          ),
          retryWhen: (error, attempt) => false,
          action: () async {
            calls++;
            throw Exception('fail');
          },
        ),
        throwsException,
      );

      expect(calls, 1);
    });

    test('passes the error and zero based attempt to retryWhen', () async {
      final seenAttempts = <int>[];
      final seenErrors = <Object>[];

      await expectLater(
        RetryHandler.execute<String>(
          config: RetryConfig(
            maxAttempts: 2,
            initialDelay: fast,
            retryWhen: (error, attempt) {
              seenErrors.add(error);
              seenAttempts.add(attempt);
              return true;
            },
          ),
          action: () async => throw StateError('fail'),
        ),
        throwsStateError,
      );

      expect(seenAttempts, [0, 1]);
      expect(seenErrors, everyElement(isA<StateError>()));
    });

    test('returns the value after a successful retry', () async {
      var calls = 0;

      final result = await RetryHandler.execute<String>(
        config: const RetryConfig(maxAttempts: 3, initialDelay: fast),
        action: () async {
          calls++;
          if (calls < 3) throw Exception('fail');
          return 'ok';
        },
      );

      expect(result, 'ok');
      expect(calls, 3);
    });

    test('returns immediately when the first attempt succeeds', () async {
      var calls = 0;

      final result = await RetryHandler.execute<int>(
        config: const RetryConfig(maxAttempts: 3, initialDelay: fast),
        action: () async {
          calls++;
          return 7;
        },
      );

      expect(result, 7);
      expect(calls, 1);
    });

    test('waits between attempts', () async {
      final stopwatch = Stopwatch()..start();

      await expectLater(
        RetryHandler.execute<String>(
          config: const RetryConfig(
            maxAttempts: 2,
            backoff: BackoffStrategy.fixed,
            initialDelay: Duration(milliseconds: 30),
          ),
          action: () async => throw Exception('fail'),
        ),
        throwsException,
      );

      // Two retries x 30 ms. Allow some timer slack.
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
    });
  });

  group('RetryConfig.getDelay', () {
    test('exponential backoff doubles the delay', () {
      const config = RetryConfig(
        backoff: BackoffStrategy.exponential,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 60),
      );

      expect(config.getDelay(0), const Duration(milliseconds: 100));
      expect(config.getDelay(1), const Duration(milliseconds: 200));
      expect(config.getDelay(2), const Duration(milliseconds: 400));
      expect(config.getDelay(3), const Duration(milliseconds: 800));
    });

    test('linear backoff grows by initialDelay', () {
      const config = RetryConfig(
        backoff: BackoffStrategy.linear,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 60),
      );

      expect(config.getDelay(0), const Duration(milliseconds: 100));
      expect(config.getDelay(1), const Duration(milliseconds: 200));
      expect(config.getDelay(2), const Duration(milliseconds: 300));
    });

    test('fixed backoff always returns initialDelay', () {
      const config = RetryConfig(
        backoff: BackoffStrategy.fixed,
        initialDelay: Duration(milliseconds: 250),
      );

      expect(config.getDelay(0), const Duration(milliseconds: 250));
      expect(config.getDelay(1), const Duration(milliseconds: 250));
      expect(config.getDelay(9), const Duration(milliseconds: 250));
    });

    test('maxDelay caps exponential and linear delays', () {
      const exponential = RetryConfig(
        backoff: BackoffStrategy.exponential,
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 5),
      );
      const linear = RetryConfig(
        backoff: BackoffStrategy.linear,
        initialDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 5),
      );

      expect(exponential.getDelay(2), const Duration(seconds: 4));
      expect(exponential.getDelay(3), const Duration(seconds: 5));
      expect(exponential.getDelay(50), const Duration(seconds: 5));
      expect(linear.getDelay(1), const Duration(seconds: 4));
      expect(linear.getDelay(2), const Duration(seconds: 5));
    });
  });
}
