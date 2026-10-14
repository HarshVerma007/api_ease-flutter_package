class ApiErrorInfo {
  const ApiErrorInfo({
    required this.message,
    this.statusCode,
    this.rawResponse,
    this.exception,
    this.stackTrace,
  });

  final String message;

  final int? statusCode;

  final dynamic rawResponse;

  final Object? exception;

  final StackTrace? stackTrace;

  @override
  String toString() =>
      'ApiErrorInfo(message: $message, statusCode: $statusCode)';
}
