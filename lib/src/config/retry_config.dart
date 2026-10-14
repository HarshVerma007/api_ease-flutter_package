import 'package:flutter/foundation.dart';

enum BackoffStrategy {
  fixed,
  linear,
  exponential,
}

@immutable
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 0,
    this.backoff = BackoffStrategy.exponential,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.retryWhen,
  });

  final int maxAttempts;

  final BackoffStrategy backoff;

  final Duration initialDelay;

  final Duration maxDelay;

  final bool Function(Object error, int attempt)? retryWhen;

  bool get isEnabled => maxAttempts > 0;

  Duration getDelay(int attempt) {
    final safeAttempt = attempt < 0 ? 0 : attempt;
    switch (backoff) {
      case BackoffStrategy.fixed:
        return initialDelay;
      case BackoffStrategy.linear:
        return _cap(initialDelay * (safeAttempt + 1));
      case BackoffStrategy.exponential:
        final exponent = safeAttempt > 30 ? 30 : safeAttempt;
        return _cap(initialDelay * (1 << exponent));
    }
  }

  Duration _cap(Duration value) => value > maxDelay ? maxDelay : value;

  RetryConfig copyWith({
    int? maxAttempts,
    BackoffStrategy? backoff,
    Duration? initialDelay,
    Duration? maxDelay,
    bool Function(Object error, int attempt)? retryWhen,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      backoff: backoff ?? this.backoff,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      retryWhen: retryWhen ?? this.retryWhen,
    );
  }
}
