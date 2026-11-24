import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/models/password_reset_model.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';

class AuthService {
  AuthService({
    this.loginEndpoint,
    this.registerEndpoint,
    this.forgotPasswordEndpoint,
    this.resetPasswordEndpoint,
    HttpClient? client,
    TokenStore? tokenStore,
  }) : _client = client ?? HttpClient(),
       _tokenStore = tokenStore ?? SecureTokenStore();

  final Uri? loginEndpoint;
  final Uri? registerEndpoint;
  final Uri? forgotPasswordEndpoint;
  final Uri? resetPasswordEndpoint;
  final HttpClient _client;
  final TokenStore _tokenStore;

  Uri get _loginUri => loginEndpoint ?? Apis.login;
  Uri get _registerUri => registerEndpoint ?? Apis.register;
  Uri get _forgotPasswordUri => forgotPasswordEndpoint ?? Apis.forgotPassword;
  Uri get _resetPasswordUri => resetPasswordEndpoint ?? Apis.resetPassword;

  Future<LoginResponseModel> login(LoginModel model) async {
    final responseBody = await _post(_loginUri, model.toJson());
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta de inicio no es válida.');
    }

    final response = LoginResponseModel.fromJson(decoded);
    await _tokenStore.save(response.token);
    return response;
  }

  Future<void> register(RegisterModel model) async {
    await _post(_registerUri, model.toJson());
  }

  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest model,
  ) async {
    final responseBody = await _post(_forgotPasswordUri, model.toJson());
    if (responseBody.trim().isEmpty) return const ForgotPasswordResponse();
    return ForgotPasswordResponse.fromJson(
      _decodeResponse(
        responseBody,
        'La respuesta de recuperación no es válida.',
      ),
    );
  }

  Future<ResetPasswordResponse> resetPassword(
    ResetPasswordRequest model,
  ) async {
    final responseBody = await _post(_resetPasswordUri, model.toJson());
    if (responseBody.trim().isEmpty) return const ResetPasswordResponse();
    return ResetPasswordResponse.fromJson(
      _decodeResponse(
        responseBody,
        'La respuesta de cambio de contraseña no es válida.',
      ),
    );
  }

  Future<Map<String, String>> authorizationHeaders() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw StateError('No hay una sesión activa para esta solicitud.');
    }
    return {HttpHeaders.authorizationHeader: 'Bearer $token'};
  }

  Future<void> logout() => _tokenStore.clear();

  Future<String> _post(Uri endpoint, Map<String, dynamic> body) async {
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

    return responseBody;
  }

  Map<String, dynamic> _decodeResponse(
    String responseBody,
    String errorMessage,
  ) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(errorMessage);
    }
    return decoded;
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
