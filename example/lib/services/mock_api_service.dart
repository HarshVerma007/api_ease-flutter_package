import 'dart:async';

/// A user returned by the mock API.
class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  final int id;
  final String name;
  final String email;
}

/// Converts a mock API response (`{'success': true, 'data': [...]}`) into
/// users. Used as the `transformer` of the examples.
List<AppUser> parseUsers(dynamic response) {
  final map = response as Map<String, dynamic>;
  return (map['data'] as List<dynamic>)
      .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Exception thrown by the mock API to simulate a network failure.
class MockNetworkException implements Exception {
  const MockNetworkException(this.message);

  final String message;

  @override
  String toString() => 'MockNetworkException: $message';
}

/// A fake backend with configurable latency and failure modes. It works with
/// no network at all, so the examples behave the same everywhere.
class MockApiService {
  MockApiService({this.delay = const Duration(milliseconds: 1200)});

  /// Simulated latency of every call.
  final Duration delay;

  int _flakyAttempts = 0;

  static const List<String> _names = [
    'Ada Lovelace',
    'Alan Turing',
    'Grace Hopper',
    'Linus Torvalds',
    'Margaret Hamilton',
    'Dennis Ritchie',
    'Barbara Liskov',
    'Ken Thompson',
    'Radia Perlman',
    'Donald Knuth',
    'Katherine Johnson',
    'Tim Berners-Lee',
    'Hedy Lamarr',
    'Guido van Rossum',
    'Annie Easley',
    'James Gosling',
    'Sophie Wilson',
    'Anders Hejlsberg',
    'Frances Allen',
    'Brendan Eich',
  ];

  List<Map<String, dynamic>> _users(int from, int count) {
    final result = <Map<String, dynamic>>[];
    for (var i = from; i < from + count && i < _names.length; i++) {
      final name = _names[i];
      result.add(<String, dynamic>{
        'id': i + 1,
        'name': name,
        'email': '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
      });
    }
    return result;
  }

  /// Returns a user list after [delay].
  Future<Map<String, dynamic>> fetchUsers() async {
    await Future<void>.delayed(delay);
    return <String, dynamic>{'success': true, 'data': _users(0, 8)};
  }

  /// Returns an *invalid* response (HTTP 422) after [delay]. The example
  /// validator rejects it, which produces an `ApiError`.
  Future<Map<String, dynamic>> fetchWithError() async {
    await Future<void>.delayed(delay);
    return <String, dynamic>{
      'success': false,
      'statusCode': 422,
      'message': 'The server rejected the request (422).',
    };
  }

  /// Throws a [MockNetworkException] after [delay].
  Future<Map<String, dynamic>> fetchWithException() async {
    await Future<void>.delayed(delay);
    throw const MockNetworkException('Connection reset by peer');
  }

  /// Returns one page (1 based) of users. Page 5 and beyond are empty.
  Future<Map<String, dynamic>> fetchUsersPage(
    int page, {
    int pageSize = 5,
  }) async {
    await Future<void>.delayed(delay);
    return <String, dynamic>{
      'success': true,
      'data': _users((page - 1) * pageSize, pageSize),
    };
  }

  /// Fails the first [failTimes] attempts, then succeeds. [onAttempt]
  /// receives the 1 based attempt number.
  Future<Map<String, dynamic>> fetchFlaky({
    required int failTimes,
    void Function(int attempt)? onAttempt,
  }) async {
    _flakyAttempts++;
    final attempt = _flakyAttempts;
    onAttempt?.call(attempt);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (attempt <= failTimes) {
      throw MockNetworkException('Temporary failure (attempt $attempt)');
    }
    return <String, dynamic>{'success': true, 'data': _users(0, 4)};
  }

  /// Resets the attempt counter used by [fetchFlaky].
  void resetFlaky() => _flakyAttempts = 0;
}
