import 'dart:async';

import 'package:api_ease/api_ease.dart';
import 'package:api_ease/src/core/connectivity_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(ConnectivityChecker.resetOverrides);

  test('returns true when the connectivity check passes', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest = (url, timeout) async => true;

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(),
      ),
      isTrue,
    );
  });

  test('returns false when there is no physical network', () async {
    var headCalls = 0;
    ConnectivityChecker.physicalCheck = () async => false;
    ConnectivityChecker.headRequest = (url, timeout) async {
      headCalls++;
      return true;
    };

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(),
      ),
      isFalse,
    );
    expect(headCalls, 0);
  });

  test('returns false when the HEAD request fails', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest = (url, timeout) async => false;

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(),
      ),
      isFalse,
    );
  });

  test('returns false when the HEAD request throws', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest =
        (url, timeout) => Future.error(Exception('socket error'));

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(),
      ),
      isFalse,
    );
  });

  test('returns false when the HEAD request times out', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest =
        (url, timeout) => Completer<bool>().future; // never completes

    final stopwatch = Stopwatch()..start();
    final result = await ConnectivityChecker.hasInternetConnection(
      const ConnectivityConfig(timeout: Duration(milliseconds: 50)),
    );

    expect(result, isFalse);
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('returns true when one of several endpoints succeeds', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest =
        (url, timeout) async => url.contains('good');

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(
          endpoints: ['https://bad.example', 'https://good.example'],
        ),
      ),
      isTrue,
    );
  });

  test('does not wait for slow endpoints once one succeeded', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest = (url, timeout) {
      if (url.contains('slow')) return Completer<bool>().future;
      return Future<bool>.value(true);
    };

    final result = await ConnectivityChecker.hasInternetConnection(
      const ConnectivityConfig(
        endpoints: ['https://slow.example', 'https://fast.example'],
        timeout: Duration(seconds: 2),
      ),
    );

    expect(result, isTrue);
  });

  test('returns false when every endpoint fails', () async {
    ConnectivityChecker.physicalCheck = () async => true;
    ConnectivityChecker.headRequest = (url, timeout) async => false;

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(
          endpoints: ['https://a.example', 'https://b.example'],
        ),
      ),
      isFalse,
    );
  });

  test('returns true without checking when disabled', () async {
    var physicalCalls = 0;
    ConnectivityChecker.physicalCheck = () async {
      physicalCalls++;
      return false;
    };

    expect(
      await ConnectivityChecker.hasInternetConnection(
        const ConnectivityConfig(enabled: false),
      ),
      isTrue,
    );
    expect(physicalCalls, 0);
  });
}
