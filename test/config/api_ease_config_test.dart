import 'package:api_ease/api_ease.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ApiEase.resetForTest);

  group('ApiEaseConfig defaults', () {
    test('uses safe defaults', () {
      const config = ApiEaseConfig();

      expect(config.connectivity.enabled, isTrue);
      expect(config.connectivity.endpoints,
          ['https://clients3.google.com/generate_204']);
      expect(config.connectivity.timeout, const Duration(seconds: 3));
      expect(config.noInternetDialog.enabled, isTrue);
      expect(config.noInternetDialog.deduplicate, isTrue);
      expect(config.noInternetDialog.builder, isNull);
      expect(config.retry.maxAttempts, 0);
      expect(config.retry.backoff, BackoffStrategy.exponential);
      expect(config.retry.initialDelay, const Duration(milliseconds: 500));
      expect(config.retry.maxDelay, const Duration(seconds: 10));
      expect(config.debounce.enabled, isFalse);
      expect(config.debounce.window, const Duration(milliseconds: 300));
      expect(config.loading.showOverlay, isFalse);
      expect(config.loading.overlayWidget, isNull);
      expect(config.responseValidator, isNull);
      expect(config.errorMessageExtractor, isNull);
      expect(config.enableLogging, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      const original = ApiEaseConfig(enableLogging: true);
      final copy = original.copyWith(
        retry: const RetryConfig(maxAttempts: 2),
      );

      expect(copy.enableLogging, isTrue);
      expect(copy.retry.maxAttempts, 2);
      expect(copy.connectivity, same(original.connectivity));
    });
  });

  group('ApiEase.init', () {
    test('stores the given configuration', () {
      const config = ApiEaseConfig(enableLogging: true);

      expect(ApiEase.isInitialized, isFalse);
      ApiEase.init(config: config);

      expect(ApiEase.isInitialized, isTrue);
      expect(ApiEase.config, same(config));
    });

    test('resetForTest restores defaults', () {
      ApiEase.init(config: const ApiEaseConfig(enableLogging: true));
      ApiEase.resetForTest();

      expect(ApiEase.isInitialized, isFalse);
      expect(ApiEase.config.enableLogging, isFalse);
    });
  });

  group('RetryConfig', () {
    test('isEnabled reflects maxAttempts', () {
      expect(const RetryConfig().isEnabled, isFalse);
      expect(const RetryConfig(maxAttempts: 1).isEnabled, isTrue);
    });

    test('copyWith keeps unspecified values', () {
      const config = RetryConfig(maxAttempts: 3);
      final copy = config.copyWith(backoff: BackoffStrategy.fixed);

      expect(copy.maxAttempts, 3);
      expect(copy.backoff, BackoffStrategy.fixed);
    });
  });
}
