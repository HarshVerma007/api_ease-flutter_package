import '../config/retry_config.dart';
import '../utils/logger.dart';

class RetryHandler {
  RetryHandler._();

  static Future<T> execute<T>({
    required Future<T> Function() action,
    required RetryConfig config,
    bool Function(Object error, int attempt)? retryWhen,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        if (attempt >= config.maxAttempts) {
          rethrow;
        }
        final shouldRetry =
            (retryWhen ?? config.retryWhen)?.call(error, attempt) ?? true;
        if (!shouldRetry) {
          rethrow;
        }
        final delay = config.getDelay(attempt);
        ApiEaseLogger.log(
          'Attempt ${attempt + 1} failed ($error). '
          'Retrying in ${delay.inMilliseconds} ms.',
        );
        await Future<void>.delayed(delay);
        attempt++;
      }
    }
  }
}
