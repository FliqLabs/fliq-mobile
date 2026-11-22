import 'dart:convert';

import 'package:http/http.dart' as http;

/// A request the Fliq API refused or that never reached it.
///
/// The API answers errors as `{"error": {"code": "...", "message": "..."}}`.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status});

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;
      return ApiException(
        status: response.statusCode,
        code: error['code'] as String? ?? 'unknown',
        message: error['message'] as String? ?? 'Something went wrong.',
      );
    } catch (_) {
      return ApiException(
        status: response.statusCode,
        code: 'unknown',
        message: 'The server answered ${response.statusCode}.',
      );
    }
  }

  const ApiException.signedOut()
    : status = 401,
      code = 'signed_out',
      message = 'Your session ended. Sign in again.';

  const ApiException.offline()
    : status = null,
      code = 'offline',
      message = "Can't reach fliq. Check your connection and try again.";

  /// HTTP status, or null when the request never got an answer.
  final int? status;
  final String code;
  final String message;

  bool get isSignedOut => status == 401;

  @override
  String toString() => 'ApiException($status, $code): $message';
}
