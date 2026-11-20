import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';

class AuthService {
  AuthService({
    required this.loginEndpoint,
    required this.registerEndpoint,
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final Uri loginEndpoint;
  final Uri registerEndpoint;
  final HttpClient _client;

  Future<void> login(LoginModel model) => _post(loginEndpoint, model.toJson());

  Future<void> register(RegisterModel model) =>
      _post(registerEndpoint, model.toJson());

  Future<void> _post(Uri endpoint, Map<String, dynamic> body) async {
    final request = await _client
        .postUrl(endpoint)
        .timeout(const Duration(seconds: 15));
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    request.write(jsonEncode(body));

    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      if (responseBody.isNotEmpty) {
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map) message = decoded['message']?.toString();
        } on FormatException {
          message = null;
        }
      }
      throw AuthApiException(
        statusCode: response.statusCode,
        message: message ?? response.reasonPhrase,
      );
    }
  }

  void close() => _client.close();
}

class AuthApiException implements Exception {
  const AuthApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}
