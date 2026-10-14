import 'connectivity_config.dart';
import 'debounce_config.dart';
import 'loading_config.dart';
import 'no_internet_dialog_config.dart';
import 'retry_config.dart';

class ApiEaseConfig {
  const ApiEaseConfig({
    this.connectivity = const ConnectivityConfig(),
    this.noInternetDialog = const NoInternetDialogConfig(),
    this.retry = const RetryConfig(),
    this.debounce = const DebounceConfig(),
    this.loading = const LoadingConfig(),
    this.responseValidator,
    this.errorMessageExtractor,
    this.enableLogging = false,
  });

  final ConnectivityConfig connectivity;

  final NoInternetDialogConfig noInternetDialog;

  final RetryConfig retry;

  final DebounceConfig debounce;

  final LoadingConfig loading;

  final bool Function(dynamic response)? responseValidator;

  final String Function(dynamic response)? errorMessageExtractor;

  final bool enableLogging;

  ApiEaseConfig copyWith({
    ConnectivityConfig? connectivity,
    NoInternetDialogConfig? noInternetDialog,
    RetryConfig? retry,
    DebounceConfig? debounce,
    LoadingConfig? loading,
    bool Function(dynamic response)? responseValidator,
    String Function(dynamic response)? errorMessageExtractor,
    bool? enableLogging,
  }) {
    return ApiEaseConfig(
      connectivity: connectivity ?? this.connectivity,
      noInternetDialog: noInternetDialog ?? this.noInternetDialog,
      retry: retry ?? this.retry,
      debounce: debounce ?? this.debounce,
      loading: loading ?? this.loading,
      responseValidator: responseValidator ?? this.responseValidator,
      errorMessageExtractor:
          errorMessageExtractor ?? this.errorMessageExtractor,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
}
