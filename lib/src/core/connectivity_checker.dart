import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/connectivity_config.dart';
import '../utils/logger.dart';

class ConnectivityChecker {
  ConnectivityChecker._();

  @visibleForTesting
  static Future<bool> Function() physicalCheck = _defaultPhysicalCheck;

  @visibleForTesting
  static Future<bool> Function(String url, Duration timeout) headRequest =
      _defaultHeadRequest;

  static void resetOverrides() {
    physicalCheck = _defaultPhysicalCheck;
    headRequest = _defaultHeadRequest;
  }

  static Future<bool> hasInternetConnection(ConnectivityConfig config) async {
    if (!config.enabled) {
      return true;
    }

    final hasNetwork = await physicalCheck();
    if (!hasNetwork) {
      ApiEaseLogger.log('No network interface available.');
      return false;
    }

    if (config.endpoints.isEmpty) {
      return true;
    }

    final completer = Completer<bool>();
    var pending = config.endpoints.length;

    for (final url in config.endpoints) {
      unawaited(
        _probe(url, config.timeout).then((reachable) {
          if (completer.isCompleted) return;
          if (reachable) {
            completer.complete(true);
          } else {
            pending--;
            if (pending == 0) {
              completer.complete(false);
            }
          }
        }, onError: (_) {
          if (completer.isCompleted) return;
          pending--;
          if (pending == 0) {
            completer.complete(false);
          }
        }),
      );
    }

    final result = await completer.future;
    if (!result) {
      ApiEaseLogger.log('No endpoint reachable.');
    }
    return result;
  }

  static Future<bool> _probe(String url, Duration timeout) {
    return headRequest(url, timeout)
        .timeout(timeout, onTimeout: () => false)
        .catchError((_) => false);
  }

  static Future<bool> _defaultPhysicalCheck() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  static Future<bool> _defaultHeadRequest(String url, Duration timeout) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.openUrl('HEAD', Uri.parse(url));
      final response = await request.close();
      await response.drain<void>();

      return response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
