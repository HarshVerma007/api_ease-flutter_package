import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

/// Demonstrates the default and a fully custom no-internet dialog.
///
/// The demo swaps the global `ApiEase` configuration while it is visible and
/// restores the app configuration when it is left.
class CustomDialogExample extends StatefulWidget {
  const CustomDialogExample({super.key});

  @override
  State<CustomDialogExample> createState() => _CustomDialogExampleState();
}

class _CustomDialogExampleState extends State<CustomDialogExample> {
  final _api = MockApiService();

  bool _simulateOffline = true;
  bool _useCustomDialog = false;
  bool _loading = false;
  String _status = 'Press a button to send a request.';

  Widget _customDialog(BuildContext context, VoidCallback onRetry) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.cloud_off_rounded, size: 40, color: scheme.error),
      title: const Text("You're offline"),
      content: const Text(
        'This is a custom dialog built with NoInternetDialogConfig.builder.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }

  /// Applies the global configuration matching the current toggles. It is
  /// re-applied when the switch changes, so the dialog's Retry button uses
  /// the latest connectivity setting.
  void _applyConfig() {
    final base = _simulateOffline ? kOfflineConfig : kExampleConfig;
    ApiEase.init(
      config: base.copyWith(
        noInternetDialog: NoInternetDialogConfig(
          builder: _useCustomDialog ? _customDialog : null,
        ),
      ),
    );
  }

  Future<void> _send({required bool custom}) async {
    _useCustomDialog = custom;
    _applyConfig();

    await ApiEase.call<List<AppUser>>(
      request: _api.fetchUsers,
      context: context,
      transformer: parseUsers,
      onLoadingChanged: (isLoading) => setState(() => _loading = isLoading),
      onSuccess: (users) =>
          setState(() => _status = '✅ Loaded ${users.length} users.'),
      onError: (error) => setState(() => _status = '❌ ${error.message}'),
    );
  }

  @override
  void dispose() {
    ApiEase.init(config: kExampleConfig);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExampleHeader(
            title: 'No-internet dialog',
            description:
                'When there is no connection, api_ease shows a dialog and '
                'its Retry button re-runs the request. Switch "offline" off '
                'and press Retry to see the request succeed.',
            code: 'ApiEase.init(\n'
                '  config: ApiEaseConfig(\n'
                '    noInternetDialog: NoInternetDialogConfig(\n'
                '      builder: (context, onRetry) => MyDialog(onRetry),\n'
                '    ),\n'
                '  ),\n'
                ');',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _simulateOffline,
            onChanged: (value) {
              setState(() => _simulateOffline = value);
              _applyConfig();
            },
            title: const Text('Simulate offline'),
            subtitle: const Text('Points the connectivity probe at a closed port'),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => _send(custom: false),
                  child: const Text('Default dialog'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _loading ? null : () => _send(custom: true),
                  child: const Text('Custom dialog'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(_status, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
