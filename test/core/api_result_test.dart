import 'package:api_ease/api_ease.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const errorInfo = ApiErrorInfo(message: 'boom', statusCode: 500);

  group('when', () {
    test('calls success for ApiSuccess', () {
      const ApiResult<int> result = ApiSuccess(42);

      final value = result.when(
        success: (data) => 'success $data',
        error: (error) => 'error',
        noInternet: () => 'offline',
      );

      expect(value, 'success 42');
    });

    test('calls error for ApiError', () {
      const ApiResult<int> result = ApiError(errorInfo);

      final value = result.when(
        success: (data) => 'success',
        error: (error) => 'error ${error.message}',
        noInternet: () => 'offline',
      );

      expect(value, 'error boom');
    });

    test('calls noInternet for ApiNoInternet', () {
      const ApiResult<int> result = ApiNoInternet();

      final value = result.when(
        success: (data) => 'success',
        error: (error) => 'error',
        noInternet: () => 'offline',
      );

      expect(value, 'offline');
    });
  });

  group('maybeWhen', () {
    test('uses the matching handler', () {
      const ApiResult<int> result = ApiSuccess(1);

      expect(
        result.maybeWhen(success: (data) => 'yes', orElse: () => 'no'),
        'yes',
      );
    });

    test('falls back to orElse when the handler is missing', () {
      const ApiResult<int> success = ApiSuccess(1);
      const ApiResult<int> error = ApiError(errorInfo);
      const ApiResult<int> offline = ApiNoInternet();

      expect(
        success.maybeWhen(error: (e) => 'error', orElse: () => 'else'),
        'else',
      );
      expect(
        error.maybeWhen(success: (d) => 'success', orElse: () => 'else'),
        'else',
      );
      expect(
        offline.maybeWhen(success: (d) => 'success', orElse: () => 'else'),
        'else',
      );
    });

    test('uses error and noInternet handlers when provided', () {
      const ApiResult<int> error = ApiError(errorInfo);
      const ApiResult<int> offline = ApiNoInternet();

      expect(
        error.maybeWhen(error: (e) => e.statusCode, orElse: () => null),
        500,
      );
      expect(
        offline.maybeWhen(noInternet: () => 'offline', orElse: () => null),
        'offline',
      );
    });
  });

  group('getters', () {
    test('ApiSuccess', () {
      const result = ApiSuccess<int>(1);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.isNoInternet, isFalse);
      expect(result.data, 1);
    });

    test('ApiError', () {
      const result = ApiError<int>(errorInfo);

      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.isNoInternet, isFalse);
      expect(result.error, same(errorInfo));
    });

    test('ApiNoInternet', () {
      const result = ApiNoInternet<int>();

      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
      expect(result.isNoInternet, isTrue);
    });
  });

  test('exhaustive switch works on the sealed class', () {
    String describe(ApiResult<int> result) => switch (result) {
          ApiSuccess(:final data) => 'data $data',
          ApiError(:final error) => 'error ${error.message}',
          ApiNoInternet() => 'offline',
        };

    expect(describe(const ApiSuccess(3)), 'data 3');
    expect(describe(const ApiError(errorInfo)), 'error boom');
    expect(describe(const ApiNoInternet()), 'offline');
  });

  test('ApiErrorInfo.toString contains message and status code', () {
    expect(errorInfo.toString(), contains('boom'));
    expect(errorInfo.toString(), contains('500'));
  });
}
