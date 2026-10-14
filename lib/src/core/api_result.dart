import 'api_error_info.dart';

sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiErrorInfo error) error,
    required R Function() noInternet,
  });

  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(ApiErrorInfo error)? error,
    R Function()? noInternet,
    required R Function() orElse,
  });

  bool get isSuccess;

  bool get isError;

  bool get isNoInternet;
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiErrorInfo error) error,
    required R Function() noInternet,
  }) =>
      success(data);

  @override
  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(ApiErrorInfo error)? error,
    R Function()? noInternet,
    required R Function() orElse,
  }) =>
      success != null ? success(data) : orElse();

  @override
  bool get isSuccess => true;

  @override
  bool get isError => false;

  @override
  bool get isNoInternet => false;

  @override
  String toString() => 'ApiSuccess($data)';
}

class ApiError<T> extends ApiResult<T> {
  const ApiError(this.error);

  final ApiErrorInfo error;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiErrorInfo error) error,
    required R Function() noInternet,
  }) =>
      error(this.error);

  @override
  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(ApiErrorInfo error)? error,
    R Function()? noInternet,
    required R Function() orElse,
  }) =>
      error != null ? error(this.error) : orElse();

  @override
  bool get isSuccess => false;

  @override
  bool get isError => true;

  @override
  bool get isNoInternet => false;

  @override
  String toString() => 'ApiError($error)';
}

class ApiNoInternet<T> extends ApiResult<T> {
  const ApiNoInternet();

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiErrorInfo error) error,
    required R Function() noInternet,
  }) =>
      noInternet();

  @override
  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(ApiErrorInfo error)? error,
    R Function()? noInternet,
    required R Function() orElse,
  }) =>
      noInternet != null ? noInternet() : orElse();

  @override
  bool get isSuccess => false;

  @override
  bool get isError => false;

  @override
  bool get isNoInternet => true;

  @override
  String toString() => 'ApiNoInternet()';
}
