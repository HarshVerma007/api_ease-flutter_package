import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/retry_config.dart';
import '../core/api_ease_core.dart';
import '../core/api_error_info.dart';
import '../core/api_result.dart';
import 'api_call_controller.dart';
import 'api_state.dart';

class ApiCall<T> extends StatefulWidget {
  const ApiCall({
    super.key,
    required this.request,
    this.autoFetch = true,
    this.controller,
    this.builder,
    this.loadingBuilder,
    this.successBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.offlineBuilder,
    this.transformer,
    this.emptyWhen,
    this.responseValidator,
    this.errorMessageExtractor,
    this.retry,
    this.skipInternetCheck = false,
  }) : assert(
          builder != null || successBuilder != null,
          'Provide either `builder` or at least a `successBuilder`.',
        );

  final Future<dynamic> Function() request;

  final bool autoFetch;

  final ApiCallController? controller;

  final Widget Function(BuildContext context, ApiState<T> state)? builder;

  final Widget Function(BuildContext context)? loadingBuilder;

  final Widget Function(BuildContext context, T data)? successBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final Widget Function(
    BuildContext context,
    ApiErrorInfo error,
    VoidCallback retry,
  )? errorBuilder;

  final Widget Function(BuildContext context, VoidCallback retry)?
      offlineBuilder;

  final T Function(dynamic responseData)? transformer;

  final bool Function(T data)? emptyWhen;

  final bool Function(dynamic response)? responseValidator;

  final String Function(dynamic response)? errorMessageExtractor;

  final RetryConfig? retry;

  final bool skipInternetCheck;

  @override
  State<ApiCall<T>> createState() => _ApiCallState<T>();
}

class _ApiCallState<T> extends State<ApiCall<T>> {
  ApiState<T>? _state;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(_fetch);
    if (widget.autoFetch) {
      _state = ApiLoading<T>();
      _fetch();
    }
  }

  @override
  void didUpdateWidget(ApiCall<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(_fetch);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _requestId++;
    super.dispose();
  }

  void _fetch() {
    unawaited(_load());
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    if (_state is! ApiLoading<T>) {
      setState(() => _state = ApiLoading<T>());
    }

    final result = await ApiEase.run<T>(
      request: widget.request,
      responseValidator: widget.responseValidator,
      errorMessageExtractor: widget.errorMessageExtractor,
      retry: widget.retry,
      skipInternetCheck: widget.skipInternetCheck,
      transformer: widget.transformer,
    );

    if (!mounted || requestId != _requestId) return;
    setState(() => _state = _mapResult(result));
  }

  ApiState<T> _mapResult(ApiResult<T> result) {
    switch (result) {
      case ApiSuccess<T>(:final data):
        final isEmpty = widget.emptyWhen?.call(data) ?? false;
        return isEmpty ? ApiEmpty<T>() : ApiLoaded<T>(data);
      case ApiError<T>(:final error):
        return ApiErrorState<T>(error: error, retry: _fetch);
      case ApiNoInternet<T>():
        return ApiOffline<T>(retry: _fetch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final builder = widget.builder;
    if (builder != null) {
      return builder(context, state);
    }

    switch (state) {
      case ApiLoading<T>():
        return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
      case ApiLoaded<T>(:final data):
        return widget.successBuilder?.call(context, data) ??
            const SizedBox.shrink();
      case ApiEmpty<T>():
        return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
      case ApiErrorState<T>(:final error, :final retry):
        return widget.errorBuilder?.call(context, error, retry) ??
            const SizedBox.shrink();
      case ApiOffline<T>(:final retry):
        return widget.offlineBuilder?.call(context, retry) ??
            const SizedBox.shrink();
    }
  }
}
