import 'package:flutter/widgets.dart';

class NoInternetDialogConfig {
  const NoInternetDialogConfig({
    this.enabled = true,
    this.deduplicate = true,
    this.builder,
  });

  final bool enabled;

  final bool deduplicate;

  final Widget Function(BuildContext context, VoidCallback onRetry)? builder;
}
