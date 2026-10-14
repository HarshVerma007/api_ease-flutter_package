import 'package:flutter/material.dart';

class DefaultNoInternetDialog extends StatelessWidget {
  const DefaultNoInternetDialog({
    super.key,
    this.onRetry,
    this.title = 'No Internet Connection',
    this.message = 'Please check your connection and try again.',
    this.retryLabel = 'Retry',
    this.dismissLabel = 'Dismiss',
  });

  final VoidCallback? onRetry;

  final String title;

  final String message;

  final String retryLabel;

  final String dismissLabel;

  static int _openDialogs = 0;

  @visibleForTesting
  static bool get isShowing => _openDialogs > 0;

  @visibleForTesting
  static void resetForTesting() => _openDialogs = 0;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onRetry,
    bool deduplicate = true,
  }) async {
    if (deduplicate && _openDialogs > 0) return;
    _openDialogs++;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => DefaultNoInternetDialog(onRetry: onRetry),
      );
    } finally {
      _openDialogs--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = Color(0xFFE65100);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.92 + 0.08 * value, child: child),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x26FF6D00),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 38,
                  color: accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry?.call();
                  },
                  child: Text(retryLabel),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(dismissLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
