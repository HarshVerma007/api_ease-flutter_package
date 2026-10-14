import 'package:flutter/widgets.dart';

class MountedGuard {
  MountedGuard._();

  static void run(BuildContext? context, VoidCallback action) {
    if (context != null && context.mounted) {
      action();
    }
  }

  static Future<void> runAsync(
    BuildContext? context,
    Future<void> Function() action,
  ) async {
    if (context != null && context.mounted) {
      await action();
    }
  }

  static void runSafely(BuildContext? context, VoidCallback action) {
    if (context == null || context.mounted) {
      action();
    }
  }
}
