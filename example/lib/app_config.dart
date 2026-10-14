import 'package:api_ease/api_ease.dart';

/// The mock API answers with `{'success': bool, 'message': String, ...}`.
bool isSuccessResponse(dynamic response) =>
    response is Map<String, dynamic> && response['success'] == true;

String extractErrorMessage(dynamic response) {
  if (response is Map<String, dynamic>) {
    return (response['message'] as String?) ?? 'Something went wrong.';
  }
  return 'Something went wrong.';
}

/// Global configuration used by the whole example app.
const ApiEaseConfig kExampleConfig = ApiEaseConfig(
  enableLogging: true,
  responseValidator: isSuccessResponse,
  errorMessageExtractor: extractErrorMessage,
);

/// Same as [kExampleConfig] but the connectivity probe points at a closed
/// local port, so every request looks "offline". Used by the dialog demo.
final ApiEaseConfig kOfflineConfig = kExampleConfig.copyWith(
  connectivity: const ConnectivityConfig(
    endpoints: ['http://127.0.0.1:9'],
    timeout: Duration(seconds: 2),
  ),
);
