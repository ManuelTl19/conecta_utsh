import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';

class UserProfileService {
  UserProfileService({required this.authService, this.onUnauthorized});

  final AuthService authService;
  final Future<void> Function()? onUnauthorized;
  Future<void>? _unauthorizedTask;

  Future<UserProfile> obtenerPerfil({UserProfile? fallback}) async {
    final response = await _request(
      method: 'GET',
      endpoint: Apis.authMe,
      operation: _UserProfileOperation.read,
    );
    try {
      return UserProfile.fromApiJson(response, fallback: fallback);
    } on FormatException {
      throw const UserProfileApiException(
        message: 'El servidor devolvió datos de perfil no válidos.',
      );
    }
  }

  Future<void> actualizarPerfil(Map<String, dynamic> changes) async {
    await _request(
      method: 'PATCH',
      endpoint: Apis.updateOwnProfile,
      body: changes,
      operation: _UserProfileOperation.update,
    );
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String nuevaPassword,
    required String confirmarPassword,
  }) async {
    await _request(
      method: 'PATCH',
      endpoint: Apis.changeOwnPassword,
      body: {
        'passwordActual': passwordActual,
        'nuevaPassword': nuevaPassword,
        'confirmarPassword': confirmarPassword,
      },
      operation: _UserProfileOperation.changePassword,
    );
  }

  Future<void> eliminarCuenta({required String password}) async {
    await _request(
      method: 'DELETE',
      endpoint: Apis.deleteOwnProfile,
      body: {'password': password},
      operation: _UserProfileOperation.deleteAccount,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri endpoint,
    required _UserProfileOperation operation,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await authService.authenticatedRequest(
        method: method,
        endpoint: endpoint,
        body: body,
      );
      if (operation != _UserProfileOperation.read) {
        return const {};
      }
      if (response.trim().isEmpty) {
        throw const FormatException('La respuesta del perfil está vacía.');
      }
      final decoded = _decodeResponse(response);
      return decoded;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 ||
          (error.statusCode == 403 &&
              (operation == _UserProfileOperation.update ||
                  operation == _UserProfileOperation.changePassword))) {
        await _notifyUnauthorized();
      }
      throw _mapApiError(error, operation);
    } on StateError {
      await _notifyUnauthorized();
      throw const UserProfileApiException(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException {
      throw const UserProfileApiException(
        message: 'No se pudo acceder a tu sesión.',
      );
    } on SocketException {
      throw const UserProfileApiException(
        message: 'No hay conexión. Revisa tu internet.',
      );
    } on TimeoutException {
      throw const UserProfileApiException(
        message: 'El servidor tardó demasiado. Intenta de nuevo.',
      );
    } on HttpException {
      throw const UserProfileApiException(
        message: 'Hubo un problema en el servidor. Intenta más tarde.',
      );
    } on FormatException {
      throw const UserProfileApiException(
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(String response) {
    final decoded = jsonDecode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del perfil no es válida.');
    }
    return decoded;
  }

  UserProfileApiException _mapApiError(
    AuthApiException error,
    _UserProfileOperation operation,
  ) {
    final serverMessage = error.message.trim();
    final message = switch (operation) {
      _UserProfileOperation.read => switch (error.statusCode) {
        401 => 'Tu sesión ha expirado. Inicia sesión de nuevo.',
        >= 500 => 'Hubo un problema en el servidor. Intenta más tarde.',
        _ => 'No se pudo cargar tu perfil.',
      },
      _UserProfileOperation.update => switch (error.statusCode) {
        400 => _spanishMessageOr(serverMessage, 'Revisa los datos ingresados.'),
        403 => 'Tu cuenta está desactivada.',
        409 =>
          'Tus datos cambiaron mientras editabas. Revisa e intenta de nuevo.',
        >= 500 => 'Hubo un problema en el servidor. Intenta más tarde.',
        _ => 'No se pudo actualizar tu perfil.',
      },
      _UserProfileOperation.changePassword => switch (error.statusCode) {
        400 => 'La contraseña actual es incorrecta o los datos no son válidos.',
        403 => 'Tu cuenta está desactivada.',
        409 => 'No se pudo completar el cambio. Intenta de nuevo.',
        429 => 'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        >= 500 => 'Hubo un problema en el servidor. Intenta más tarde.',
        _ => 'No se pudo cambiar la contraseña.',
      },
      _UserProfileOperation.deleteAccount => switch (error.statusCode) {
        400 => 'Contraseña incorrecta.',
        403 => 'Esta operación no está permitida para tu cuenta.',
        404 => 'No encontramos tu cuenta.',
        409 => 'No se pudo completar la operación. Intenta de nuevo.',
        429 => 'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        >= 500 => 'Hubo un problema en el servidor. Intenta más tarde.',
        _ => 'No se pudo eliminar tu cuenta.',
      },
    };

    return UserProfileApiException(
      statusCode: error.statusCode,
      message: message,
      retryAfterSeconds: error.retryAfterSeconds,
    );
  }

  String _spanishMessageOr(String message, String fallback) {
    final normalized = message.toLowerCase();
    final looksSpanish =
        RegExp(r'[áéíóúñ¿¡]').hasMatch(normalized) ||
        RegExp(
          r'\b(el|la|los|las|tu|tus|debes|ingresa|revisa|campo|datos|contraseña|correo|telefono|teléfono|debe|selecciona|obligatorio)\b',
        ).hasMatch(normalized);
    if (message.isEmpty || !looksSpanish) {
      return fallback;
    }
    return message;
  }

  Future<void> _notifyUnauthorized() async {
    final callback = onUnauthorized;
    if (callback == null) return;
    _unauthorizedTask ??= callback();
    try {
      await _unauthorizedTask;
    } finally {
      _unauthorizedTask = null;
    }
  }
}

enum _UserProfileOperation { read, update, changePassword, deleteAccount }

class UserProfileApiException implements Exception {
  const UserProfileApiException({
    this.statusCode,
    required this.message,
    this.retryAfterSeconds,
  });

  final int? statusCode;
  final String message;
  final int? retryAfterSeconds;

  @override
  String toString() => message;
}
