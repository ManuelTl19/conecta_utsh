import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';

class UserProfileService {
  UserProfileService({
    required this.authService,
    Uri? endpoint,
    HttpClient? client,
    this.useMock = true,
  }) : _endpoint = endpoint ?? Apis.currentUser,
       _client = client ?? HttpClient();

  final AuthService authService;
  final Uri _endpoint;
  final HttpClient _client;
  final bool useMock;
  UserProfile _mockProfile = _initialMockProfile;

  Future<UserProfile> getCurrentUser() async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return _mockProfile;
    }
    final responseBody = await _request('GET');
    final decoded = _decodeResponse(responseBody);
    return UserProfile.fromApiJson(decoded);
  }

  Future<void> updateCurrentUser(UserProfileUpdate profile) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      _mockProfile = _mockProfile.withUpdate(profile);
      return;
    }
    await _request('PUT', body: profile.toJson());
  }

  Future<String> _request(String method, {Map<String, dynamic>? body}) async {
    final request = await _client
        .openUrl(method, _endpoint)
        .timeout(const Duration(seconds: 15));
    final authorization = await authService.authorizationHeaders();
    request.headers
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
      ..set(
        HttpHeaders.authorizationHeader,
        authorization[HttpHeaders.authorizationHeader]!,
      );
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
      throw UserProfileApiException(
        statusCode: response.statusCode,
        message: _errorMessage(responseBody) ?? response.reasonPhrase,
      );
    }
    return responseBody;
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del perfil no es válida.');
    }
    return decoded;
  }

  String? _errorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return decoded['message']?.toString();
    } on FormatException {
      return null;
    }
    return null;
  }

  void close() => _client.close();
}

const _initialMockProfile = UserProfile(
  nombre: 'María',
  apellidoPaterno: 'Hernández',
  apellidoMaterno: 'López',
  matricula: '2023001234',
  direccion: 'Tecnologías de la Información',
  carrera: 'Ingeniería en Desarrollo y Gestión de Software',
  cuatrimestre: 7,
  correo: 'estudiante@example.test',
  telefono: '7711234567',
  rol: 'estudiante',
  favoriteCount: 4,
  estadoEstadia: 'En proceso',
  citasPendientes: 1,
  citasConfirmadas: 1,
  createdAt: '2026-01-15T00:00:00.000Z',
);

class UserProfileApiException implements Exception {
  const UserProfileApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String? message;

  @override
  String toString() =>
      'UserProfileApiException($statusCode): ${message ?? 'Error del servidor'}';
}
