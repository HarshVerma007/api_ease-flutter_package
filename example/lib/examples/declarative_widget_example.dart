import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

/// Demonstrates the declarative `ApiCall` widget with a controller.
class DeclarativeWidgetExample extends StatefulWidget {
  const DeclarativeWidgetExample({super.key});

  @override
  State<DeclarativeWidgetExample> createState() =>
      _DeclarativeWidgetExampleState();
}

class _DeclarativeWidgetExampleState extends State<DeclarativeWidgetExample> {
  final _api = MockApiService();
  final _controller = ApiCallController();

  @override
  void dispose() {
    _controller.dispose();
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
            title: 'ApiCall widget',
            description:
                'Declare what each state looks like. Loading, empty, error '
                'and offline handling come for free.',
            code: 'ApiCall<List<User>>(\n'
                '  request: api.fetchUsers,\n'
                '  controller: controller,\n'
                '  transformer: parseUsers,\n'
                '  emptyWhen: (users) => users.isEmpty,\n'
                '  loadingBuilder: ...,\n'
                '  successBuilder: ...,\n'
                '  errorBuilder: (ctx, e, retry) => ...,\n'
                ')',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _controller.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh via controller'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ApiCall<List<AppUser>>(
              request: _api.fetchUsers,
              controller: _controller,
              transformer: parseUsers,
              emptyWhen: (users) => users.isEmpty,
              loadingBuilder: (context) =>
                  const LoadingView(label: 'Fetching users…'),
              successBuilder: (context, users) => UserList(users: users),
              emptyBuilder: (context) => const StatusView(
                icon: Icons.group_off_outlined,
                title: 'No users yet',
              ),
              errorBuilder: (context, error, retry) => StatusView(
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                title: 'Something went wrong',
                message: error.message,
                actionLabel: 'Try again',
                onAction: retry,
              ),
              offlineBuilder: (context, retry) => StatusView(
                icon: Icons.wifi_off_rounded,
                title: 'You are offline',
                message: 'Check your connection and retry.',
                actionLabel: 'Retry',
                onAction: retry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
