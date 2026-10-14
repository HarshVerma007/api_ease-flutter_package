import 'package:flutter/widgets.dart';

class LoadingConfig {
  const LoadingConfig({
    this.showOverlay = false,
    this.overlayWidget,
  });

  final bool showOverlay;

  final Widget? overlayWidget;
}
