import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class NearRpcException implements Exception {
  const NearRpcException(this.message);

  final String message;

  bool get isUnknownAccessKey =>
      message.contains('UNKNOWN_ACCESS_KEY') ||
      message.contains('does not exist');

  @override
  String toString() => 'NearRpcException: $message';
}

/// What the phone reads from the NEAR chain itself: its key's nonce and the
/// latest final block. Ported from the iPhone app's NEARRPC.swift.
class NearRpc {
  NearRpc({http.Client? client, String? url})
    : _client = client ?? http.Client(),
      _url = url ?? ApiConfig.nearRpcUrl;

  static NearRpc instance = NearRpc();

  final http.Client _client;
  final String _url;

  /// The nonce of [publicKey] on [account]. The next delegate uses one more.
  Future<BigInt> accessKeyNonce(String account, String publicKey) async {
    final result = await _call('query', {
      'request_type': 'view_access_key',
      'finality': 'final',
      'account_id': account,
      'public_key': publicKey,
    });
    final error = result['error'];
    if (error is String) throw NearRpcException(error);
    return BigInt.parse(result['nonce'].toString());
  }

  /// Whether [publicKey] can sign for [account] right now. Anything other
  /// than a clear yes or no is thrown, never guessed.
  Future<bool> hasAccessKey(String account, String publicKey) async {
    try {
      await accessKeyNonce(account, publicKey);
      return true;
    } on NearRpcException catch (error) {
      if (error.isUnknownAccessKey) return false;
      rethrow;
    }
  }

  Future<BigInt> finalBlockHeight() async {
    final result = await _call('block', {'finality': 'final'});
    final header = result['header'] as Map<String, dynamic>;
    return BigInt.parse(header['height'].toString());
  }

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, dynamic> params,
  ) async {
    final response = await _client
        .post(
          Uri.parse(_url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 'fliq',
            'method': method,
            'params': params,
          }),
        )
        .timeout(const Duration(seconds: 30));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'];
    if (error is Map) {
      final cause = error['cause'];
      throw NearRpcException(
        [
          if (cause is Map) cause['name'],
          error['message'],
          error['data'],
        ].whereType<Object>().join(': '),
      );
    }
    return body['result'] as Map<String, dynamic>;
  }
}
