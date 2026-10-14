// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/api_ease_config.dart';
import '../config/retry_config.dart';
import '../utils/logger.dart';
import '../widgets/default_no_internet_dialog.dart';
import 'api_error_info.dart';
import 'api_result.dart';
import 'connectivity_checker.dart';
import 'debounce_handler.dart';
import 'mounted_guard.dart';
import 'retry_handler.dart';

class _OverlayHandle {
  _OverlayHandle(this._navigator, this._route);

  final NavigatorState _navigator;
  final Route<void> _route;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    try {
      if (_navigator.mounted && _route.isActive) {
        _navigator.removeRoute(_route);
      }
    } catch (error) {
      ApiEaseLogger.log('Could not remove loading overlay: $error');
    }
  }
}

class ApiEase {
  ApiEase._();

  static ApiEaseConfig _config = const ApiEaseConfig();
  static bool _initialized = false;
  static bool _dialogShowing = false;

  static void init({ApiEaseConfig config = const ApiEaseConfig()}) {
    _config = config;
    _initialized = true;
  }

  static ApiEaseConfig get config => _config;

  static bool get isInitialized => _initialized;

  @visibleForTesting
  static void resetForTest() {
    _config = const ApiEaseConfig();
    _initialized = false;
    _dialogShowing = false;
    DebounceHandler.cancelAll();
  }

  static Future<void> call<T>({
    required Future<dynamic> Function() request,
    BuildContext? context,
    void Function(T data)? onSuccess,
    void Function(ApiErrorInfo error)? onError,
    void Function(bool isLoading)? onLoadingChanged,
    void Function()? onNoInternet,
    bool Function(dynamic response)? responseValidator,
    String Function(dynamic response)? errorMessageExtractor,
    RetryConfig? retry,
    String? debounceKey,
    bool skipInternetCheck = false,
    T Function(dynamic responseData)? transformer,
  }) async {
    await _execute<T>(
      request: request,
      context: context,
      onLoadingChanged: onLoadingChanged,
      responseValidator: responseValidator,
      errorMessageExtractor: errorMessageExtractor,
      retry: retry,
      debounceKey: debounceKey,
      skipInternetCheck: skipInternetCheck,
      transformer: transformer,
      onResult: (result) {
        switch (result) {
          case ApiSuccess<T>(:final data):
            MountedGuard.runSafely(context, () => onSuccess?.call(data));
          case ApiError<T>(:final error):
            MountedGuard.runSafely(context, () => onError?.call(error));
          case ApiNoInternet<T>():
            if (onNoInternet != null) {
              MountedGuard.runSafely(context, onNoInternet);
            } else {
              unawaited(
                _showNoInternetDialog(
                  context,
                  () => call<T>(
                    request: request,
                    context: context,
                    onSuccess: onSuccess,
                    onError: onError,
                    onLoadingChanged: onLoadingChanged,
                    onNoInternet: onNoInternet,
                    responseValidator: responseValidator,
                    errorMessageExtractor: errorMessageExtractor,
                    retry: retry,
                    debounceKey: debounceKey,
                    skipInternetCheck: skipInternetCheck,
                    transformer: transformer,
                  ),
                ),
              );
            }
        }
      },
    );
  }

  static Future<ApiResult<T>> run<T>({
    required Future<dynamic> Function() request,
    BuildContext? context,
    bool Function(dynamic response)? responseValidator,
    String Function(dynamic response)? errorMessageExtractor,
    RetryConfig? retry,
    String? debounceKey,
    bool skipInternetCheck = false,
    T Function(dynamic responseData)? transformer,
  }) {
    return _execute<T>(
      request: request,
      context: context,
      onLoadingChanged: null,
      responseValidator: responseValidator,
      errorMessageExtractor: errorMessageExtractor,
      retry: retry,
      debounceKey: debounceKey,
      skipInternetCheck: skipInternetCheck,
      transformer: transformer,
      onResult: null,
    );
  }

  static Future<ApiResult<T>> _execute<T>({
    required Future<dynamic> Function() request,
    required BuildContext? context,
    required void Function(bool isLoading)? onLoadingChanged,
    required bool Function(dynamic response)? responseValidator,
    required String Function(dynamic response)? errorMessageExtractor,
    required RetryConfig? retry,
    required String? debounceKey,
    required bool skipInternetCheck,
    required T Function(dynamic responseData)? transformer,
    required void Function(ApiResult<T> result)? onResult,
  }) async {
    MountedGuard.runSafely(context, () => onLoadingChanged?.call(true));
    final overlay = _showLoadingOverlay(context);

    final ApiResult<T> result;
    try {
      result = await _perform<T>(
        request: request,
        responseValidator: responseValidator,
        errorMessageExtractor: errorMessageExtractor,
        retry: retry,
        debounceKey: debounceKey,
        skipInternetCheck: skipInternetCheck,
        transformer: transformer,
      );
      overlay?.dismiss();
      if (result is! ApiNoInternet<T>) {
        onResult?.call(result);
      }
    } finally {
      overlay?.dismiss();
      MountedGuard.runSafely(context, () => onLoadingChanged?.call(false));
    }

    if (result is ApiNoInternet<T>) {
      onResult?.call(result);
    }
    return result;
  }

  static Future<ApiResult<T>> _perform<T>({
    required Future<dynamic> Function() request,
    required bool Function(dynamic response)? responseValidator,
    required String Function(dynamic response)? errorMessageExtractor,
    required RetryConfig? retry,
    required String? debounceKey,
    required bool skipInternetCheck,
    required T Function(dynamic responseData)? transformer,
  }) async {
    try {
      if (!skipInternetCheck && _config.connectivity.enabled) {
        final online = await ConnectivityChecker.hasInternetConnection(
            _config.connectivity);
        if (!online) {
          ApiEaseLogger.log('No internet connection.');
          return ApiNoInternet<T>();
        }
      }

      final effectiveRetry = retry ?? _config.retry;
      Future<dynamic> attempt() {
        if (effectiveRetry.isEnabled) {
          return RetryHandler.execute<dynamic>(
            action: request,
            config: effectiveRetry,
          );
        }
        return request();
      }

      final dynamic response = (debounceKey != null && _config.debounce.enabled)
          ? await DebounceHandler.execute<dynamic>(
              key: debounceKey,
              action: attempt,
              config: _config.debounce,
            )
          : await attempt();

      final validator = responseValidator ?? _config.responseValidator;
      final isValid = validator?.call(response) ?? true;
      if (!isValid) {
        final message = _extractMessage(
          response,
          errorMessageExtractor ?? _config.errorMessageExtractor,
        );
        ApiEaseLogger.log('Invalid response: $message');
        return ApiError<T>(
          ApiErrorInfo(
            message: message,
            statusCode: _statusCodeOf(response),
            rawResponse: response,
          ),
        );
      }

      final T data;
      if (transformer != null) {
        data = transformer(response);
      } else if (response is T) {
        data = response;
      } else {
        throw StateError(
          'Expected a response of type $T but got '
          '${response.runtimeType}. Provide a transformer to convert it.',
        );
      }
      return ApiSuccess<T>(data);
    } catch (error, stackTrace) {
      ApiEaseLogger.log('Request failed: $error');
      return ApiError<T>(_errorFromException(error, stackTrace));
    }
  }

  static String _extractMessage(
    dynamic response,
    String Function(dynamic response)? extractor,
  ) {
    const fallback = 'The server returned an invalid response.';
    if (extractor == null) return fallback;
    try {
      final message = extractor(response);
      return message.isEmpty ? fallback : message;
    } catch (_) {
      return fallback;
    }
  }

  static int? _statusCodeOf(dynamic response) {
    if (response is Map<dynamic, dynamic>) {
      final dynamic value = response['statusCode'] ??
          response['status_code'] ??
          response['status'];
      return value is int ? value : null;
    }
    try {
      final dynamic value = (response as dynamic).statusCode;
      if (value is int) return value;
    } catch (_) {
      // The object has no statusCode property.
    }
    return null;
  }

  static ApiErrorInfo _errorFromException(
    Object error,
    StackTrace stackTrace,
  ) {
    String? message;
    int? statusCode;
    dynamic rawResponse;

    try {
      final dynamic value = (error as dynamic).message;
      if (value is String && value.isNotEmpty) message = value;
    } catch (_) {
      // The exception has no message property.
    }

    try {
      final dynamic response = (error as dynamic).response;
      if (response != null) {
        statusCode = _statusCodeOf(response);
        try {
          rawResponse = (response as dynamic).data;
        } catch (_) {
          // The attached response has no data property.
        }
      }
    } catch (_) {
      // The exception has no response property.
    }

    return ApiErrorInfo(
      message: message ?? error.toString(),
      statusCode: statusCode,
      rawResponse: rawResponse,
      exception: error,
      stackTrace: stackTrace,
    );
  }

  static _OverlayHandle? _showLoadingOverlay(BuildContext? context) {
    final loading = _config.loading;
    if (!loading.showOverlay || context == null || !context.mounted) {
      return null;
    }
    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      final route = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Material(
          type: MaterialType.transparency,
          child: loading.overlayWidget ??
              const Center(child: CircularProgressIndicator()),
        ),
      );
      unawaited(navigator.push(route));
      return _OverlayHandle(navigator, route);
    } catch (error) {
      ApiEaseLogger.log('Could not show loading overlay: $error');
      return null;
    }
  }

  static Future<void> _showNoInternetDialog(
    BuildContext? context,
    VoidCallback onRetry,
  ) async {
    final dialogConfig = _config.noInternetDialog;
    if (!dialogConfig.enabled) return;
    if (context == null || !context.mounted) {
      ApiEaseLogger.log(
        'No-internet dialog skipped: no mounted context available.',
      );
      return;
    }
    if (dialogConfig.deduplicate && _dialogShowing) return;

    _dialogShowing = true;
    try {
      final builder = dialogConfig.builder;
      if (builder != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => builder(dialogContext, () {
            Navigator.of(dialogContext).pop();
            onRetry();
          }),
        );
      } else {
        await DefaultNoInternetDialog.show(
          context,
          onRetry: onRetry,
          deduplicate: dialogConfig.deduplicate,
        );
      }
    } finally {
      _dialogShowing = false;
    }
  }
}
