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

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget buildApiCall<T>({
    ApiCallController? controller,
    bool autoFetch = true,
    Future<dynamic> Function()? request,
    T Function(dynamic)? transformer,
    bool Function(T)? emptyWhen,
    bool skipInternetCheck = false,
  }) {
    return wrap(
      ApiCall<T>(
        request: request ?? () => api.fetch(),
        controller: controller,
        autoFetch: autoFetch,
        transformer: transformer,
        emptyWhen: emptyWhen,
        skipInternetCheck: skipInternetCheck,
        loadingBuilder: (context) => const Text('loading'),
        successBuilder: (context, data) => Text('success: $data'),
        emptyBuilder: (context) => const Text('empty'),
        errorBuilder: (context, error, retry) => Column(
          children: [
            Text('error: ${error.message}'),
            ElevatedButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
        offlineBuilder: (context, retry) => Column(
          children: [
            const Text('offline'),
            ElevatedButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  group('fetching', () {
    testWidgets('autoFetch: true triggers the request on init',
        (tester) async {
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApiCall<String>());

      verify(() => api.fetch()).called(1);
      completer.complete('data');
      await tester.pumpAndSettle();
    });

    testWidgets('autoFetch: false does not fetch until controller.fetch()',
        (tester) async {
      final controller = ApiCallController();
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildApiCall<String>(controller: controller, autoFetch: false),
      );
      await tester.pumpAndSettle();

      verifyNever(() => api.fetch());
      expect(find.text('loading'), findsNothing);
      expect(controller.isAttached, isTrue);

      controller.fetch();
      await tester.pump();

      verify(() => api.fetch()).called(1);
      expect(find.text('loading'), findsOneWidget);

      completer.complete('data');
      await tester.pumpAndSettle();
      expect(find.text('success: data'), findsOneWidget);
    });

    testWidgets('controller detaches when the widget is disposed',
        (tester) async {
      final controller = ApiCallController();
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      await tester.pumpWidget(buildApiCall<String>(controller: controller));
      await tester.pumpAndSettle();
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const SizedBox());
      expect(controller.isAttached, isFalse);
      controller.fetch(); // must be a harmless no-op
    });
  });

  group('states', () {
    testWidgets('loading state shows the loadingBuilder', (tester) async {
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApiCall<String>());

      expect(find.text('loading'), findsOneWidget);

      completer.complete('data');
      await tester.pumpAndSettle();
    });

    testWidgets('success state shows the successBuilder', (tester) async {
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApiCall<String>());
      completer.complete('hello');
      await tester.pumpAndSettle();

      expect(find.text('success: hello'), findsOneWidget);
      expect(find.text('loading'), findsNothing);
    });

    testWidgets('empty state shows the emptyBuilder when emptyWhen is true',
        (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => <int>[]);

      await tester.pumpWidget(
        buildApiCall<List<int>>(emptyWhen: (data) => data.isEmpty),
      );
      await tester.pumpAndSettle();

      expect(find.text('empty'), findsOneWidget);
      expect(find.textContaining('success'), findsNothing);
    });

    testWidgets('non-empty data still shows the successBuilder',
        (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => <int>[1]);

      await tester.pumpWidget(
        buildApiCall<List<int>>(emptyWhen: (data) => data.isEmpty),
      );
      await tester.pumpAndSettle();

      expect(find.text('success: [1]'), findsOneWidget);
      expect(find.text('empty'), findsNothing);
    });

    testWidgets('error state shows the errorBuilder', (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => throw Exception('fail'));

      await tester.pumpWidget(buildApiCall<String>());
      await tester.pumpAndSettle();

      expect(find.text('error: fail'), findsOneWidget);
    });

    testWidgets('offline state shows the offlineBuilder', (tester) async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      await tester.pumpWidget(buildApiCall<String>());
      await tester.pumpAndSettle();

      expect(find.text('offline'), findsOneWidget);
      verifyNever(() => api.fetch());
    });

    testWidgets('applies the transformer', (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => '21');

      await tester.pumpWidget(
        buildApiCall<int>(
          transformer: (response) => int.parse(response as String) * 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('success: 42'), findsOneWidget);
    });

    testWidgets('skipInternetCheck ignores a missing connection',
        (tester) async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      await tester.pumpWidget(buildApiCall<String>(skipInternetCheck: true));
      await tester.pumpAndSettle();

      expect(find.text('success: data'), findsOneWidget);
    });

    testWidgets('missing convenience builders render nothing', (tester) async {
      when(() => api.fetch()).thenAnswer((_) async => throw Exception('fail'));

      await tester.pumpWidget(
        wrap(
          ApiCall<String>(
            request: () => api.fetch(),
            successBuilder: (context, data) => Text(data),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.textContaining('fail'), findsNothing);
    });

    testWidgets('the generic builder receives every state', (tester) async {
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);
      final seen = <Type>[];

      await tester.pumpWidget(
        wrap(
          ApiCall<String>(
            request: () => api.fetch(),
            builder: (context, state) {
              seen.add(state.runtimeType);
              return switch (state) {
                ApiLoaded<String>(:final data) => Text('data: $data'),
                _ => const Text('other'),
              };
            },
          ),
        ),
      );
      expect(seen.first, ApiLoading<String>);

      completer.complete('x');
      await tester.pumpAndSettle();

      expect(seen.last, ApiLoaded<String>);
      expect(find.text('data: x'), findsOneWidget);
    });
  });

  group('retry and refresh', () {
    testWidgets('the retry callback re-triggers the fetch', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        buildApiCall<String>(
          request: () async {
            calls++;
            if (calls == 1) throw Exception('first failure');
            return 'recovered';
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('error: first failure'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('success: recovered'), findsOneWidget);
    });

    testWidgets('offline retry works once the connection is back',
        (tester) async {
      ConnectivityChecker.physicalCheck = () async => false;
      when(() => api.fetch()).thenAnswer((_) async => 'data');

      await tester.pumpWidget(buildApiCall<String>());
      await tester.pumpAndSettle();
      expect(find.text('offline'), findsOneWidget);

      ConnectivityChecker.physicalCheck = () async => true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('success: data'), findsOneWidget);
    });

    testWidgets('controller.refresh() re-triggers the fetch', (tester) async {
      final controller = ApiCallController();
      var calls = 0;

      await tester.pumpWidget(
        buildApiCall<String>(
          controller: controller,
          request: () async => 'call ${++calls}',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('success: call 1'), findsOneWidget);

      controller.refresh();
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('success: call 2'), findsOneWidget);
    });

    testWidgets('only the latest request wins', (tester) async {
      final controller = ApiCallController();
      final completers = <Completer<dynamic>>[];

      await tester.pumpWidget(
        buildApiCall<String>(
          controller: controller,
          request: () {
            final completer = Completer<dynamic>();
            completers.add(completer);
            return completer.future;
          },
        ),
      );
      await tester.pump();
      controller.fetch();
      await tester.pump();
      expect(completers, hasLength(2));

      completers[1].complete('second');
      await tester.pumpAndSettle();
      completers[0].complete('first');
      await tester.pumpAndSettle();

      expect(find.text('success: second'), findsOneWidget);
      expect(find.text('success: first'), findsNothing);
    });

    testWidgets('a result arriving after dispose is ignored', (tester) async {
      final completer = Completer<dynamic>();
      when(() => api.fetch()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildApiCall<String>());
      await tester.pumpWidget(const SizedBox());

      completer.complete('late');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
