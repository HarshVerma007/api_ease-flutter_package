import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

enum _Scenario { success, serverError, exception }

/// Demonstrates `ApiEase.run()` and the sealed `ApiResult`.
class ResultPatternExample extends StatefulWidget {
  const ResultPatternExample({super.key});

  @override
  State<ResultPatternExample> createState() => _ResultPatternExampleState();
}

class _ResultPatternExampleState extends State<ResultPatternExample> {
  final _api = MockApiService();

  _Scenario _scenario = _Scenario.success;
  bool _loading = false;
  ApiResult<List<AppUser>>? _result;

  Future<dynamic> _request() {
    switch (_scenario) {
      case _Scenario.success:
        return _api.fetchUsers();
      case _Scenario.serverError:
        return _api.fetchWithError();
      case _Scenario.exception:
        return _api.fetchWithException();
    }
  }

  Future<void> _run() async {
    setState(() => _loading = true);
    final result = await ApiEase.run<List<AppUser>>(
      request: _request,
      transformer: parseUsers,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExampleHeader(
            title: 'ApiEase.run()',
            description:
                'Returns a sealed ApiResult instead of using callbacks. '
                'Pick a scenario and run it.',
            code: 'final result = await ApiEase.run<List<User>>(\n'
                '  request: api.fetchUsers,\n'
                '  transformer: parseUsers,\n'
                ');\n'
                'switch (result) {\n'
                '  case ApiSuccess(:final data): ...\n'
                '  case ApiError(:final error): ...\n'
                '  case ApiNoInternet(): ...\n'
                '}',
          ),
          const SizedBox(height: 12),
          SegmentedButton<_Scenario>(
            segments: const [
              ButtonSegment(value: _Scenario.success, label: Text('Success')),
              ButtonSegment(
                value: _Scenario.serverError,
                label: Text('Server error'),
              ),
              ButtonSegment(
                value: _Scenario.exception,
                label: Text('Exception'),
              ),
            ],
            selected: {_scenario},
            onSelectionChanged: (selection) =>
                setState(() => _scenario = selection.first),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run'),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    final result = _result;
    if (result == null) {
      return const StatusView(
        icon: Icons.rule_rounded,
        title: 'No result yet',
        message: 'Choose a scenario and press Run.',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return switch (result) {
      ApiSuccess(:final data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Chip(
              avatar: const Icon(Icons.check_circle, size: 18),
              label: Text('ApiSuccess • ${data.length} users'),
            ),
            Expanded(child: UserList(users: data)),
          ],
        ),
      ApiError(:final error) => StatusView(
          icon: Icons.error_outline,
          color: scheme.error,
          title: 'ApiError',
          message: '${error.message}'
              '${error.statusCode != null ? ' (status ${error.statusCode})' : ''}',
        ),
      ApiNoInternet() => StatusView(
          icon: Icons.wifi_off_rounded,
          color: scheme.tertiary,
          title: 'ApiNoInternet',
          message: 'The request was not sent.',
        ),
    };
  }
}
