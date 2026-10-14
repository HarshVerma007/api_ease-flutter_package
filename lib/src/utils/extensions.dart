import 'package:flutter/widgets.dart';

import '../core/api_ease_core.dart';
import '../core/connectivity_checker.dart';

extension ApiEaseContextExtensions on BuildContext {
  Future<bool> get hasInternet =>
      ConnectivityChecker.hasInternetConnection(ApiEase.config.connectivity);
}
