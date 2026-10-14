## 1.0.0

Initial release.

### Added

- `ApiEase.call()`: callback-based API with `onSuccess`, `onError`, `onLoadingChanged` and `onNoInternet`.
- `ApiEase.run()`: returns a sealed `ApiResult` (`ApiSuccess`, `ApiError`, `ApiNoInternet`) with `when` and `maybeWhen`.
- `ApiCall` widget and `ApiCallController`: declarative loading, success, empty, error and offline states.
- Internet check that verifies the network interface and probes real endpoints.
- Customizable no-internet dialog with a polished Material 3 default and retry support.
- Global and per-call response validation and error message extraction.
- Retry with fixed, linear or exponential backoff and a `retryWhen` rule.
- In-flight request de-duplication through `debounceKey`.
- Automatic `context.mounted` guard for all callbacks.
- Optional loading overlay.
- `BuildContext.hasInternet` extension.
- Works with any HTTP client (Dio, `http`, Retrofit, Chopper, ...).

### Platforms

- Android, iOS, macOS, Windows and Linux. Web is not supported.