import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

/// Demonstrates retry with fixed / linear / exponential backoff.
class RetryExample extends StatefulWidget {
  const RetryExample({super.key});

  @override
  State<RetryExample> createState() => _RetryExampleState();
}

class _RetryExampleState extends State<RetryExample> {
  final _api = MockApiService();

  BackoffStrategy _strategy = BackoffStrategy.exponential;
  double _failTimes = 2;
  bool _running = false;
  final List<String> _log = [];

  Future<void> _run() async {
    _api.resetFlaky();
    final stopwatch = Stopwatch()..start();
    final failTimes = _failTimes.round();
    final retry = RetryConfig(
      maxAttempts: 4,
      backoff: _strategy,
      initialDelay: const Duration(milliseconds: 500),
    );

    setState(() {
      _running = true;
      _log
        ..clear()
        ..add('Server fails the first $failTimes attempt(s). '
            'Up to ${retry.maxAttempts} retries, ${_strategy.name} backoff.');
    });

    void add(String line) {
      if (mounted) setState(() => _log.add(line));
    }

    await ApiEase.call<List<AppUser>>(
      request: () => _api.fetchFlaky(
        failTimes: failTimes,
        onAttempt: (attempt) =>
            add('Attempt $attempt at +${stopwatch.elapsedMilliseconds} ms'),
      ),
      retry: retry,
      transformer: parseUsers,
      onSuccess: (users) => add(
        '✅ Success with ${users.length} users after '
        '${stopwatch.elapsedMilliseconds} ms',
      ),
      onError: (error) => add('❌ Gave up: ${error.message}'),
    );

    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExampleHeader(
            title: 'Retry with backoff',
            description:
                'Failed requests are retried automatically. Watch the '
                'delay between attempts change with the strategy.',
            code: 'ApiEase.call(\n'
                '  request: api.fetchUsers,\n'
                '  retry: RetryConfig(\n'
                '    maxAttempts: 4,\n'
                '    backoff: BackoffStrategy.exponential,\n'
                '    initialDelay: Duration(milliseconds: 500),\n'
                '  ),\n'
                ');',
          ),
          const SizedBox(height: 12),
          SegmentedButton<BackoffStrategy>(
            segments: const [
              ButtonSegment(value: BackoffStrategy.fixed, label: Text('Fixed')),
              ButtonSegment(
                value: BackoffStrategy.linear,
                label: Text('Linear'),
              ),
              ButtonSegment(
                value: BackoffStrategy.exponential,
                label: Text('Exponential'),
              ),
            ],
            selected: {_strategy},
            onSelectionChanged: _running
                ? null
                : (selection) => setState(() => _strategy = selection.first),
          ),
          Row(
            children: [
              Text('Failures: ${_failTimes.round()}'),
              Expanded(
                child: Slider(
                  value: _failTimes,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _failTimes.round().toString(),
                  onChanged:
                      _running ? null : (value) => setState(() => _failTimes = value),
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Run request'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _log.isEmpty
                  ? const StatusView(
                      icon: Icons.history_rounded,
                      title: 'The attempt log appears here',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _log.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) => Text(
                        _log[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
