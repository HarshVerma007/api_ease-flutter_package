import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

/// Demonstrates the callback based `ApiEase.call()`.
class SimpleCallExample extends StatefulWidget {
  const SimpleCallExample({super.key});

  @override
  State<SimpleCallExample> createState() => _SimpleCallExampleState();
}

class _SimpleCallExampleState extends State<SimpleCallExample> {
  final _api = MockApiService();

  bool _loading = false;
  List<AppUser> _users = const [];
  String? _error;

  Future<void> _run(Future<dynamic> Function() request) {
    return ApiEase.call<List<AppUser>>(
      request: request,
      context: context,
      transformer: parseUsers,
      onLoadingChanged: (isLoading) => setState(() => _loading = isLoading),
      onSuccess: (users) => setState(() {
        _users = users;
        _error = null;
      }),
      onError: (error) => setState(() {
        _users = const [];
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExampleHeader(
            title: 'ApiEase.call()',
            description:
                'One call replaces the loading flag, internet check, '
                'validation, try/catch and mounted check.',
            code: 'await ApiEase.call<List<User>>(\n'
                '  request: api.fetchUsers,\n'
                '  context: context,\n'
                '  transformer: parseUsers,\n'
                '  onLoadingChanged: (l) => setState(...),\n'
                '  onSuccess: (users) => setState(...),\n'
                '  onError: (e) => setState(...),\n'
                ');',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : () => _run(_api.fetchUsers),
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Fetch users'),
              ),
              OutlinedButton(
                onPressed: _loading ? null : () => _run(_api.fetchWithError),
                child: const Text('Server error'),
              ),
              OutlinedButton(
                onPressed:
                    _loading ? null : () => _run(_api.fetchWithException),
                child: const Text('Exception'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return StatusView(
        icon: Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        title: 'Request failed',
        message: _error,
      );
    }
    if (_users.isEmpty) {
      return const StatusView(
        icon: Icons.touch_app_outlined,
        title: 'Nothing loaded yet',
        message: 'Tap a button above to run a request.',
      );
    }
    return UserList(users: _users);
  }
}
