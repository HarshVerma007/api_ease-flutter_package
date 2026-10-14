import 'dart:async';

import 'package:api_ease/api_ease.dart';
import 'package:api_ease/src/core/connectivity_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

abstract class _Api {
  Future<dynamic> fetch();
}

class _MockApi extends Mock implements _Api {}

bool _isOk(dynamic response) => (response as Map<String, dynamic>)['ok'] == true;

String _messageOf(dynamic response) =>
    (response as Map<String, dynamic>)['message'] as String;

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    ApiEase.resetForTest();
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest = (url, timeout) async => true;
  });

  tearDown(() {
    ApiEase.resetForTest();
    ConnectivityChecker.resetOverrides();
  });

  group('ApiEase.call', () {
    test('invokes onSuccess with the response', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'hello');
      String? received;
      ApiErrorInfo? error;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        onSuccess: (data) => received = data,
        onError: (e) => error = e,
      );

      expect(received, 'hello');
      expect(error, isNull);
      verify(() => api.fetch()).called(1);
    });

    test('invokes onError when the validator rejects the response', () async {
      ApiEase.init(
        config: const ApiEaseConfig(
          responseValidator: _isOk,
          errorMessageExtractor: _messageOf,
        ),
      );
      final response = {'ok': false, 'message': 'Invalid token'};
      when(() => api.fetch()).thenAnswer((_) async => response);
      ApiErrorInfo? error;
      var successCalled = false;

      await ApiEase.call<dynamic>(
        request: () => api.fetch(),
        onSuccess: (_) => successCalled = true,
        onError: (e) => error = e,
      );

      expect(successCalled, isFalse);
      expect(error?.message, 'Invalid token');
      expect(error?.rawResponse, same(response));
    });

    test('invokes onError when the request throws', () async {
      when(() => api.fetch()).thenAnswer((_) async => throw Exception('boom'));
      ApiErrorInfo? error;
      var successCalled = false;

      await ApiEase.call<dynamic>(
        request: () => api.fetch(),
        onSuccess: (_) => successCalled = true,
        onError: (e) => error = e,
      );

      expect(successCalled, isFalse);
      expect(error, isNotNull);
      expect(error!.message, contains('boom'));
      expect(error!.exception, isA<Exception>());
      expect(error!.stackTrace, isNotNull);
    });

    test('catches synchronous exceptions thrown by the request', () async {
      ApiErrorInfo? error;

      await ApiEase.call<dynamic>(
        request: () => throw StateError('sync failure'),
        onError: (e) => error = e,
      );

      expect(error?.exception, isA<StateError>());
    });

    test('reports an error when the response has the wrong type', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'not an int');
      ApiErrorInfo? error;

      await ApiEase.call<int>(
        request: () => api.fetch(),
        onError: (e) => error = e,
      );

      expect(error?.message, contains('int'));
    });

    test('invokes onNoInternet and skips the request when offline', () async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      var offlineCalled = false;
      var successCalled = false;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        onSuccess: (_) => successCalled = true,
        onNoInternet: () => offlineCalled = true,
      );

      expect(offlineCalled, isTrue);
      expect(successCalled, isFalse);
      verifyNever(() => api.fetch());
    });

    test('skipInternetCheck bypasses the connectivity check', () async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      String? received;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        skipInternetCheck: true,
        onSuccess: (data) => received = data,
      );

      expect(received, 'data');
    });

    test('does not check connectivity when disabled in the config', () async {
      ApiEase.init(
        config: const ApiEaseConfig(
          connectivity: ConnectivityConfig(enabled: false),
        ),
      );
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      String? received;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        onSuccess: (data) => received = data,
      );

      expect(received, 'data');
    });

    test('calls onLoadingChanged with true and then false', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      final states = <bool>[];

      await ApiEase.call<String>(
        request: () => api.fetch(),
        onLoadingChanged: states.add,
      );

      expect(states, [true, false]);
    });

    test('stops loading on error and when offline', () async {
      when(() => api.fetch()).thenAnswer((_) async => throw Exception('x'));
      final errorStates = <bool>[];
      await ApiEase.call<String>(
        request: () => api.fetch(),
        onLoadingChanged: errorStates.add,
      );
      expect(errorStates, [true, false]);

      ConnectivityChecker.physicalCheck = () async => false;
      final offlineStates = <bool>[];
      await ApiEase.call<String>(
        request: () => api.fetch(),
        onLoadingChanged: offlineStates.add,
        onNoInternet: () {},
      );
      expect(offlineStates, [true, false]);
    });

    test('loading ends after onSuccess ran', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      final events = <String>[];

      await ApiEase.call<String>(
        request: () => api.fetch(),
        onLoadingChanged: (loading) => events.add('loading:$loading'),
        onSuccess: (_) => events.add('success'),
      );

      expect(events, ['loading:true', 'success', 'loading:false']);
    });

    test('a per-call responseValidator overrides the global one', () async {
      ApiEase.init(
        config: ApiEaseConfig(responseValidator: (response) => true),
      );
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      ApiErrorInfo? error;
      var successCalled = false;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        responseValidator: (response) => false,
        onSuccess: (_) => successCalled = true,
        onError: (e) => error = e,
      );

      expect(successCalled, isFalse);
      expect(error, isNotNull);
    });

    test('a per-call errorMessageExtractor overrides the global one', () async {
      ApiEase.init(
        config: ApiEaseConfig(
          responseValidator: (response) => false,
          errorMessageExtractor: (response) => 'global message',
        ),
      );
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      ApiErrorInfo? error;

      await ApiEase.call<String>(
        request: () => api.fetch(),
        errorMessageExtractor: (response) => 'per-call message',
        onError: (e) => error = e,
      );

      expect(error?.message, 'per-call message');
    });

    test('extracts the status code from a response map', () async {
      ApiEase.init(
        config: ApiEaseConfig(responseValidator: (response) => false),
      );
      when(() => api.fetch())
          .thenAnswer((_) async => {'statusCode': 404, 'message': 'x'});
      ApiErrorInfo? error;

      await ApiEase.call<dynamic>(
        request: () => api.fetch(),
        onError: (e) => error = e,
      );

      expect(error?.statusCode, 404);
    });

    test('applies the transformer', () async {
      when(() => api.fetch()).thenAnswer((_) async => {
            'items': [1, 2, 3],
          });
      List<int>? received;

      await ApiEase.call<List<int>>(
        request: () => api.fetch(),
        transformer: (response) => List<int>.from(
          (response as Map<String, dynamic>)['items'] as List<dynamic>,
        ),
        onSuccess: (data) => received = data,
      );

      expect(received, [1, 2, 3]);
    });

    test('reports an error when the transformer throws', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      ApiErrorInfo? error;

      await ApiEase.call<int>(
        request: () => api.fetch(),
        transformer: (response) => throw const FormatException('bad format'),
        onError: (e) => error = e,
      );

      expect(error?.exception, isA<FormatException>());
    });

    test('retries failing requests using the per-call RetryConfig', () async {
      var calls = 0;
      String? received;

      await ApiEase.call<String>(
        request: () async {
          calls++;
          if (calls < 3) throw Exception('flaky');
          return 'finally';
        },
        retry: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 1),
        ),
        onSuccess: (data) => received = data,
      );

      expect(received, 'finally');
      expect(calls, 3);
    });

    test('de-duplicates in-flight requests with the same debounceKey',
        () async {
      ApiEase.init(
        config: const ApiEaseConfig(
          debounce: DebounceConfig(enabled: true, window: Duration.zero),
        ),
      );
      final completer = Completer<dynamic>();
      var calls = 0;
      final received = <String>[];

      Future<dynamic> request() {
        calls++;
        return completer.future;
      }

      final first = ApiEase.call<String>(
        request: request,
        debounceKey: 'users',
        onSuccess: received.add,
      );
      final second = ApiEase.call<String>(
        request: request,
        debounceKey: 'users',
        onSuccess: received.add,
      );

      // Let both calls pass the connectivity check before completing.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      completer.complete('shared');
      await Future.wait([first, second]);

      expect(calls, 1);
      expect(received, ['shared', 'shared']);
    });

    testWidgets('does not invoke callbacks when the context is unmounted',
        (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      );
      await tester.pumpWidget(const SizedBox());
      expect(capturedContext.mounted, isFalse);

      var successCalled = false;
      var errorCalled = false;
      final loadingStates = <bool>[];

      await tester.runAsync(
        () => ApiEase.call<String>(
          request: () => api.fetch(),
          context: capturedContext,
          onSuccess: (_) => successCalled = true,
          onError: (_) => errorCalled = true,
          onLoadingChanged: loadingStates.add,
        ),
      );

      verify(() => api.fetch()).called(1);
      expect(successCalled, isFalse);
      expect(errorCalled, isFalse);
      expect(loadingStates, isEmpty);
    });

    testWidgets('invokes callbacks while the context is mounted',
        (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      );

      String? received;
      final loadingStates = <bool>[];

      await tester.runAsync(
        () => ApiEase.call<String>(
          request: () => api.fetch(),
          context: capturedContext,
          onSuccess: (data) => received = data,
          onLoadingChanged: loadingStates.add,
        ),
      );

      expect(received, 'data');
      expect(loadingStates, [true, false]);
    });

    testWidgets('shows the default dialog when offline', (tester) async {
      ConnectivityChecker.physicalCheck = () async => false;
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            capturedContext = context;
            return const Scaffold();
          }),
        ),
      );

      await tester.runAsync(
        () => ApiEase.call<String>(
          request: () => api.fetch(),
          context: capturedContext,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);
      verifyNever(() => api.fetch());

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('No Internet Connection'), findsNothing);
    });

    testWidgets('shows only one dialog when deduplicate is enabled',
        (tester) async {
      ConnectivityChecker.physicalCheck = () async => false;
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            capturedContext = context;
            return const Scaffold();
          }),
        ),
      );

      await tester.runAsync(() async {
        await ApiEase.call<String>(request: () => api.fetch(), context: capturedContext);
        await ApiEase.call<String>(request: () => api.fetch(), context: capturedContext);
      });
      await tester.pumpAndSettle();

      expect(find.byType(DefaultNoInternetDialog), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.byType(DefaultNoInternetDialog), findsNothing);
    });

    testWidgets('uses the custom dialog builder and retries from it',
        (tester) async {
      ApiEase.init(
        config: ApiEaseConfig(
          noInternetDialog: NoInternetDialogConfig(
            builder: (dialogContext, onRetry) => AlertDialog(
              title: const Text('Custom offline'),
              actions: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            capturedContext = context;
            return const Scaffold();
          }),
        ),
      );
      String? received;

      await tester.runAsync(
        () => ApiEase.call<String>(
          request: () => api.fetch(),
          context: capturedContext,
          onSuccess: (data) => received = data,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Custom offline'), findsOneWidget);
      expect(find.byType(DefaultNoInternetDialog), findsNothing);

      // Back online: the retry button runs the same call again.
      ConnectivityChecker.physicalCheck = () async => true;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Custom offline'), findsNothing);
      verify(() => api.fetch()).called(1);
      expect(received, 'data');
    });

    testWidgets('shows and removes the loading overlay', (tester) async {
      ApiEase.init(
        config: const ApiEaseConfig(
          loading: LoadingConfig(showOverlay: true),
        ),
      );
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            capturedContext = context;
            return const Scaffold();
          }),
        ),
      );

      final future = ApiEase.call<String>(
        request: () => api.fetch(),
        context: capturedContext,
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete('done');
      await tester.pump();
      await tester.pump();
      await future;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ApiEase.run', () {
    test('returns ApiSuccess on success', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      final result = await ApiEase.run<String>(request: () => api.fetch());

      expect(result, isA<ApiSuccess<String>>());
      expect(result.isSuccess, isTrue);
      expect((result as ApiSuccess<String>).data, 'data');
    });

    test('returns ApiError when the validator rejects the response', () async {
      ApiEase.init(
        config: const ApiEaseConfig(
          responseValidator: _isOk,
          errorMessageExtractor: _messageOf,
        ),
      );
      when(() => api.fetch())
          .thenAnswer((_) async => {'ok': false, 'message': 'Nope'});

      final result = await ApiEase.run<dynamic>(request: () => api.fetch());

      expect(result, isA<ApiError<dynamic>>());
      expect((result as ApiError<dynamic>).error.message, 'Nope');
    });

    test('returns ApiError when the request throws', () async {
      when(() => api.fetch()).thenAnswer((_) async => throw Exception('boom'));

      final result = await ApiEase.run<dynamic>(request: () => api.fetch());

      expect(result.isError, isTrue);
      result.when(
        success: (data) => fail('expected an error'),
        error: (error) => expect(error.message, contains('boom')),
        noInternet: () => fail('expected an error'),
      );
    });

    test('returns ApiNoInternet when offline', () async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      final result = await ApiEase.run<String>(request: () => api.fetch());

      expect(result, isA<ApiNoInternet<String>>());
      expect(result.isNoInternet, isTrue);
      verifyNever(() => api.fetch());
    });

    test('applies the transformer', () async {
      when(() => api.fetch()).thenAnswer((_) async => '21');

      final result = await ApiEase.run<int>(
        request: () => api.fetch(),
        transformer: (response) => int.parse(response as String) * 2,
      );

      expect((result as ApiSuccess<int>).data, 42);
    });

    test('honours per-call validator and message extractor', () async {
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      final result = await ApiEase.run<String>(
        request: () => api.fetch(),
        responseValidator: (response) => false,
        errorMessageExtractor: (response) => 'custom',
      );

      expect((result as ApiError<String>).error.message, 'custom');
    });
  });

  group('BuildContext.hasInternet', () {
    testWidgets('reflects the connectivity state', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox();
        }),
      );

      expect(await tester.runAsync(() => capturedContext.hasInternet), isTrue);

      ConnectivityChecker.physicalCheck = () async => false;
      expect(await tester.runAsync(() => capturedContext.hasInternet), isFalse);
    });
  });
}
