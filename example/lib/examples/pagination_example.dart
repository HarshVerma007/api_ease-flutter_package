import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import '../services/mock_api_service.dart';
import '../widgets/shared_widgets.dart';

/// Paginated list: every page is its own `ApiCall`, so each page has its own
/// loading, error and retry state.
class PaginationExample extends StatefulWidget {
  const PaginationExample({super.key});

  @override
  State<PaginationExample> createState() => _PaginationExampleState();
}

class _PaginationExampleState extends State<PaginationExample> {
  static const _maxPages = 5; // The mock API returns an empty 5th page.

  final _api = MockApiService(delay: const Duration(milliseconds: 800));
  int _pages = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagination with ApiCall')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExampleHeader(
            title: 'One ApiCall per page',
            description:
                'Each page is fetched by its own ApiCall. Pages that fail '
                'show their own retry button without affecting the others.',
          ),
          const SizedBox(height: 8),
          for (var page = 1; page <= _pages; page++)
            ApiCall<List<AppUser>>(
              key: ValueKey('page-$page'),
              request: () => _api.fetchUsersPage(page),
              transformer: parseUsers,
              emptyWhen: (users) => users.isEmpty,
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: LoadingView(label: 'Loading page…'),
              ),
              successBuilder: (context, users) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Page $page',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  UserList(users: users, shrinkWrap: true),
                ],
              ),
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: StatusView(
                  icon: Icons.flag_outlined,
                  title: "You've reached the end",
                ),
              ),
              errorBuilder: (context, error, retry) => StatusView(
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                title: 'Page $page failed',
                message: error.message,
                actionLabel: 'Retry',
                onAction: retry,
              ),
              offlineBuilder: (context, retry) => StatusView(
                icon: Icons.wifi_off_rounded,
                title: 'Offline',
                actionLabel: 'Retry',
                onAction: retry,
              ),
            ),
          if (_pages < _maxPages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _pages++),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
