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
    this.verifyResetCodeEndpoint,
    this.resetPasswordEndpoint,
    HttpClient? client,
    TokenStore? tokenStore,
  }) : _client = client ?? HttpClient(),
       _tokenStore = tokenStore ?? SecureTokenStore();

  final Uri? loginEndpoint;
  final Uri? registerEndpoint;
  final Uri? forgotPasswordEndpoint;
  final Uri? verifyResetCodeEndpoint;
  final Uri? resetPasswordEndpoint;
  final HttpClient _client;
  final TokenStore _tokenStore;

  Uri get _loginUri => loginEndpoint ?? Apis.login;
  Uri get _registerUri => registerEndpoint ?? Apis.register;
  Uri get _forgotPasswordUri => forgotPasswordEndpoint ?? Apis.forgotPassword;
  Uri get _verifyResetCodeUri =>
      verifyResetCodeEndpoint ?? Apis.verifyResetCode;
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

  Future<VerifyResetCodeResponse> verifyResetCode(
    VerifyResetCodeRequest model,
  ) async {
    final responseBody = await _post(_verifyResetCodeUri, model.toJson());
    if (responseBody.trim().isEmpty) {
      throw const FormatException(
        'La respuesta de verificación del código no es válida.',
      );
    }
    return VerifyResetCodeResponse.fromJson(
      _decodeResponse(
        responseBody,
        'La respuesta de verificación del código no es válida.',
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
    return _sendRequest(method: 'POST', endpoint: endpoint, body: body);
  }

  Future<String> authenticatedRequest({
    required String method,
    required Uri endpoint,
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw StateError('No hay una sesión activa para esta solicitud.');
    }
    return _sendRequest(
      method: method,
      endpoint: endpoint,
      body: body,
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
  }

  Future<String> _sendRequest({
    required String method,
    required Uri endpoint,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    final request = await _client
        .openUrl(method, endpoint)
        .timeout(const Duration(seconds: 15));
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    for (final header in headers.entries) {
      request.headers.set(header.key, header.value);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

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
        retryAfterSeconds: _retryAfterSeconds(
          response.headers.value('retry-after'),
        ),
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

  int? _retryAfterSeconds(String? header) {
    if (header == null) return null;
    final seconds = int.tryParse(header);
    if (seconds != null) return seconds;
    try {
      final retryAt = HttpDate.parse(header);
      final remaining = retryAt.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 1;
    } on FormatException {
      return null;
    }
  }

  void close() => _client.close();
}

class AuthApiException implements Exception {
  const AuthApiException({
    required this.statusCode,
    required this.message,
    this.retryAfterSeconds,
  });

  final int statusCode;
  final String message;
  final int? retryAfterSeconds;

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}
