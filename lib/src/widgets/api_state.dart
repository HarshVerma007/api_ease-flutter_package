import 'package:flutter/foundation.dart';

import '../core/api_error_info.dart';

sealed class ApiState<T> {
  const ApiState();
}

class ApiLoading<T> extends ApiState<T> {
  const ApiLoading();
}

class ApiLoaded<T> extends ApiState<T> {
  const ApiLoaded(this.data);

  final T data;
}

class ApiEmpty<T> extends ApiState<T> {
  const ApiEmpty();
}

class ApiErrorState<T> extends ApiState<T> {
  const ApiErrorState({required this.error, required this.retry});

  final ApiErrorInfo error;

  final VoidCallback retry;
}

class ApiOffline<T> extends ApiState<T> {
  const ApiOffline({required this.retry});

  final VoidCallback retry;
}
