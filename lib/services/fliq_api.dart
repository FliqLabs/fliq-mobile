import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Talks to the Fliq server.
class FliqApi {
  /// The API the app uses. Tests swap this for a fake so they never call
  /// the real server.

  static FliqApi instance = FliqApi();

  /// Asks the server if it is running and returns its version, e.g. "0.1.0".
  Future<String> checkHealth() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/health');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['version'] as String;
  }
}
