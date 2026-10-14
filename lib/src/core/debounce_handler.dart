import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/debounce_config.dart';
import '../utils/logger.dart';

class _Entry {
  _Entry(this.future);

  final Future<dynamic> future;
  Timer? lingerTimer;

  void dispose() {
    lingerTimer?.cancel();
    lingerTimer = null;
  }
}

class DebounceHandler {
  DebounceHandler._();

  static final Map<String, _Entry> _entries = {};

  @visibleForTesting
  static int get trackedCount => _entries.length;

  static Future<T> execute<T>({
    required String key,
    required Future<T> Function() action,
    required DebounceConfig config,
  }) {
    if (!config.enabled) {
      return action();
    }

    final existing = _entries[key];
    if (existing != null) {
      ApiEaseLogger.log('Reusing in-flight request for key "$key".');
      return existing.future as Future<T>;
    }

    final future = action();
    final entry = _Entry(future);
    _entries[key] = entry;

    unawaited(
      future.then<void>(
        (_) {
          if (!identical(_entries[key], entry)) return;
          if (config.window > Duration.zero) {
            entry.lingerTimer = Timer(config.window, () {
              if (identical(_entries[key], entry)) {
                _entries.remove(key);
              }
            });
          } else {
            _entries.remove(key);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_entries[key], entry)) {
            _entries.remove(key);
          }
        },
      ),
    );
    return future;
  }

  static void cancel(String key) {
    _entries.remove(key)?.dispose();
  }

  static void cancelAll() {
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
  }
}
