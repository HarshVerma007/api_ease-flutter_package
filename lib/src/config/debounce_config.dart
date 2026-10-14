import 'package:flutter/foundation.dart';

@immutable
class DebounceConfig {
  const DebounceConfig({
    this.enabled = false,
    this.window = const Duration(milliseconds: 300),
  });

  final bool enabled;

  final Duration window;
}
