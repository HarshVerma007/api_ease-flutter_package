<h1 align="center">api_ease</h1>

<p align="center">
  Make API calls in Flutter in <b>one line</b>.<br>
  Internet check, loading state, validation, retry, debounce and mounted checks, handled for you.
</p>

<p align="center">
  <a href="https://pub.dev/packages/api_ease"><img src="https://img.shields.io/pub/v/api_ease.svg" alt="Pub Package" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" /></a>
</p>

---

## Why api_ease?

Every API call in a Flutter app repeats the same steps: check the connection, show a loader, run the request, validate the response, handle errors, and make sure the widget is still mounted.

**Before**

```dart
Future<void> loadUsers() async {
  setState(() => _isLoading = true);

  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity.contains(ConnectivityResult.none)) {
    setState(() => _isLoading = false);
    if (!mounted) return;
    showDialog(context: context, builder: (_) => const NoInternetDialog());
    return;
  }

  try {
    final response = await dio.get('/users');
    if (response.statusCode != 200 || response.data['success'] != true) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = response.data['message'] ?? 'Something went wrong';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _users = parseUsers(response.data);
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = e.toString();
    });
  }
}
```

**After**

```dart
Future<void> loadUsers() => ApiEase.call<List<User>>(
  request: () => dio.get('/users'),
  context: context,
  transformer: (r) => parseUsers(r.data),
  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
  onSuccess: (users) => setState(() => _users = users),
  onError: (e) => setState(() => _error = e.message),
);
```

## Features

| | |
|---|---|
| **Any HTTP client** | Dio, `http`, Retrofit, Chopper or plain `dart:io`. You pass a `Future<dynamic> Function()`. |
| **Real connectivity check** | Checks the network interface, then probes real endpoints so "wifi without internet" counts as offline. |
| **No-internet dialog** | A polished Material 3 dialog with a Retry button, or plug in your own. |
| **Response validation** | Define once globally, override per call. |
| **Retry with backoff** | Fixed, linear or exponential delays, plus a `retryWhen` rule. |
| **Request de-duplication** | Identical in-flight requests share one network call. |
| **Mounted guard** | Callbacks are skipped automatically when the widget is gone. |
| **Three styles** | Callbacks (`call`), sealed results (`run`), or the declarative `ApiCall` widget. |
| **Tiny footprint** | One dependency: `connectivity_plus`. |

## Installation

```yaml
dependencies:
  api_ease: ^1.0.0
```

```dart
import 'package:api_ease/api_ease.dart';
```

**Platforms:** Android, iOS, macOS, Windows, Linux. Flutter web is not supported because the connectivity probe uses `dart:io`.

## Quick start

```dart
await ApiEase.call<String>(
request: () async => (await http.get(Uri.parse('https://example.com/hello'))).body,
context: context,
onSuccess: (text) => debugPrint(text),
onError: (e) => debugPrint(e.message),
);
```

`ApiEase.init()` is optional. Without it, sensible defaults apply.

## How a call works

```
loading(true) → connectivity check → request (retry / de-duplication)
              → validate response → transform → callback → loading(false)
```

If there is no internet, the request is never sent. `ApiEase.call` shows the no-internet dialog (or calls your `onNoInternet`), and `ApiEase.run` / `ApiCall` report it as a state.

## Three ways to use it

### 1. Callbacks: `ApiEase.call`

```dart
await ApiEase.call<List<User>>(
request: () => api.getUsers(),
context: context,                          // mounted guard, dialog, overlay
transformer: parseUsers,
onLoadingChanged: (loading) => setState(() => _loading = loading),
onSuccess: (users) => setState(() => _users = users),
onError: (error) => showSnack(error.message),
onNoInternet: () => showSnack('You are offline'), // optional, replaces the dialog
);
```

### 2. Results: `ApiEase.run`

```dart
final result = await ApiEase.run<List<User>>(
request: () => api.getUsers(),
transformer: parseUsers,
);

switch (result) {
case ApiSuccess(:final data):  showUsers(data);
case ApiError(:final error):   showError(error.message, error.statusCode);
case ApiNoInternet():          showOffline();
}
```

`run` never throws and never shows UI. `when` and `maybeWhen` are also available.

### 3. Widget: `ApiCall`

```dart
ApiCall<List<User>>(
request: () => api.getUsers(),
transformer: parseUsers,
emptyWhen: (users) => users.isEmpty,
loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
successBuilder: (context, users) => UserList(users),
emptyBuilder: (context) => const Text('No users yet'),
errorBuilder: (context, error, retry) => ErrorView(error.message, onRetry: retry),
offlineBuilder: (context, retry) => OfflineView(onRetry: retry),
)
```

Prefer one callback? Use `builder` with exhaustive pattern matching:

```dart
ApiCall<List<User>>(
request: () => api.getUsers(),
builder: (context, state) => switch (state) {
ApiLoading<List<User>>()                       => const CircularProgressIndicator(),
ApiLoaded<List<User>>(:final data)             => UserList(data),
ApiEmpty<List<User>>()                         => const Text('No users yet'),
ApiErrorState<List<User>>(:final error, :final retry) => ErrorView(error.message, retry),
ApiOffline<List<User>>(:final retry)           => OfflineView(retry),
},
)
```

Trigger it manually with a controller:

```dart
final controller = ApiCallController();

ApiCall<List<User>>(controller: controller, autoFetch: false, /* ... */);

controller.fetch(); // or controller.refresh()
```

> A builder you don't provide renders nothing, so supply an `offlineBuilder` if you want an offline screen.

## Configuration

Configure once, usually in `main()`. Every field is optional.

```dart
void main() {
  ApiEase.init(
    config: ApiEaseConfig(
      // Your backend's success rule and error format
      responseValidator: (response) => response['success'] == true,
      errorMessageExtractor: (response) => response['message'] as String,

      connectivity: const ConnectivityConfig(
        endpoints: ['https://clients3.google.com/generate_204'],
        timeout: Duration(seconds: 3),
      ),

      retry: const RetryConfig(
        maxAttempts: 2,                        // retries after the first try
        backoff: BackoffStrategy.exponential,
      ),

      debounce: const DebounceConfig(enabled: true),
      loading: const LoadingConfig(showOverlay: true),
      enableLogging: true,                     // "[ApiEase] ..." debug logs
    ),
  );
  runApp(const MyApp());
}
```

Most options can be overridden per call: `responseValidator`, `errorMessageExtractor`, `retry`, `skipInternetCheck`, `debounceKey`.

## Recipes

### Custom no-internet dialog

```dart
ApiEaseConfig(
noInternetDialog: NoInternetDialogConfig(
builder: (context, onRetry) => AlertDialog(
title: const Text('You are offline'),
actions: [
TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
FilledButton(onPressed: onRetry, child: const Text('Try again')),
],
),
),
)
```

`onRetry` closes the dialog and runs the original call again. You can also show the built-in dialog yourself with `DefaultNoInternetDialog.show(context, onRetry: ...)`.

### Retry with backoff

```dart
await ApiEase.call<Data>(
request: () => api.getData(),
retry: RetryConfig(
maxAttempts: 3,                                   // 1 try + 3 retries
backoff: BackoffStrategy.exponential,             // 500 ms, 1 s, 2 s ...
initialDelay: const Duration(milliseconds: 500),
retryWhen: (error, attempt) => isTransient(error),
),
onSuccess: (data) => /* ... */,
);
```

| Strategy | Wait after attempt `n` (starting at 0) |
|---|---|
| `fixed` | `initialDelay` |
| `linear` | `initialDelay × (n + 1)`, capped at `maxDelay` |
| `exponential` | `initialDelay × 2ⁿ`, capped at `maxDelay` |

Retries happen when the request **throws**. A response rejected by your validator is not retried.

### Prevent duplicate requests

```dart
// With DebounceConfig(enabled: true), both calls share ONE network request:
ApiEase.call<List<User>>(request: api.getUsers, debounceKey: 'users', onSuccess: show);
ApiEase.call<List<User>>(request: api.getUsers, debounceKey: 'users', onSuccess: show);
```

While a request with the same key is running, and for `DebounceConfig.window` after it *succeeds*, identical calls reuse its result. Failed requests are never cached. Use one result type per key.

### With Dio

```dart
await ApiEase.call<List<User>>(
request: () => dio.get<Map<String, dynamic>>('/users'),
responseValidator: (r) => (r as Response).statusCode == 200,
transformer: (r) => parseUsers((r as Response).data),
onSuccess: (users) => /* ... */,
);
```

A `DioException` is converted to `ApiErrorInfo` automatically, including its message, status code and response body.

### With the `http` package

```dart
await ApiEase.call<List<User>>(
request: () => http.get(Uri.parse('https://example.com/users')),
responseValidator: (r) => (r as http.Response).statusCode == 200,
errorMessageExtractor: (r) => 'HTTP ${(r as http.Response).statusCode}',
transformer: (r) => parseUsers(jsonDecode((r as http.Response).body)),
onSuccess: (users) => /* ... */,
);
```

### Quick connectivity check

```dart
if (await context.hasInternet) { /* ... */ }
```

## API reference

| Symbol | Purpose |
|---|---|
| `ApiEase.init` / `ApiEase.config` | Set and read the global configuration |
| `ApiEase.call<T>` | Callback API (`onSuccess`, `onError`, `onLoadingChanged`, `onNoInternet`) |
| `ApiEase.run<T>` | Returns `ApiResult<T>`: `ApiSuccess`, `ApiError` or `ApiNoInternet` |
| `ApiCall<T>` / `ApiCallController` | Declarative widget and its controller (`fetch`, `refresh`) |
| `ApiState<T>` | `ApiLoading`, `ApiLoaded`, `ApiEmpty`, `ApiErrorState`, `ApiOffline` |
| `ApiErrorInfo` | `message`, `statusCode`, `rawResponse`, `exception`, `stackTrace` |
| `ApiEaseConfig` | Global settings, with `copyWith` |
| `ConnectivityConfig` · `RetryConfig` · `DebounceConfig` · `LoadingConfig` · `NoInternetDialogConfig` | Per-feature settings |
| `DefaultNoInternetDialog` | The built-in dialog |
| `BuildContext.hasInternet` | Extension for a quick connectivity check |

## FAQ

**Does it depend on Dio or http?**
No. `request` is any `Future<dynamic> Function()`.

**Why wasn't my callback called?**
You passed a `context` and the widget was disposed in the meantime. That's the mounted guard. Leave `context` out if you want callbacks to always run.

**When does the dialog appear?**
In `ApiEase.call`, when offline, the dialog is enabled, a mounted `context` was passed, and no `onNoInternet` callback was given.

**What counts as an invalid response?**
Whatever your `responseValidator` rejects. Without one, every response that doesn't throw is valid.

**How do I test code that uses it?**
Disable the check in tests: `ApiEase.init(config: ApiEaseConfig(connectivity: ConnectivityConfig(enabled: false)))`, or pass `skipInternetCheck: true`.

**Is it safe with concurrent calls?**
Yes. Dart isolates are single threaded and all shared bookkeeping is updated synchronously.

## Example app

A runnable demo lives in [`example/`](example):

```bash
cd example
flutter create .
flutter run
```

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first. To report a security issue, see [SECURITY.md](SECURITY.md).

## License

Released under the [MIT License](LICENSE).