import 'package:flutter/foundation.dart';

import '../core/api_ease_core.dart';

class ApiEaseLogger {
  ApiEaseLogger._();

  static void log(String message) {
    if (ApiEase.config.enableLogging) {
      debugPrint('[ApiEase] $message');
    }
  }
}
