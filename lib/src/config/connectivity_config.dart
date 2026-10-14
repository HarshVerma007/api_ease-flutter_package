import 'package:flutter/foundation.dart';

@immutable
class ConnectivityConfig {
  const ConnectivityConfig({
    this.enabled = true,
    this.endpoints = const ['https://clients3.google.com/generate_204'],
    this.timeout = const Duration(seconds: 3),
  });

  final bool enabled;

  final List<String> endpoints;

  final Duration timeout;

  ConnectivityConfig copyWith({
    bool? enabled,
    List<String>? endpoints,
    Duration? timeout,
  }) {
    return ConnectivityConfig(
      enabled: enabled ?? this.enabled,
      endpoints: endpoints ?? this.endpoints,
      timeout: timeout ?? this.timeout,
    );
  }
}
