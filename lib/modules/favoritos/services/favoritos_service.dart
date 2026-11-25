import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/favoritos/models/favorito_item.dart';

class FavoritosService {
  FavoritosService({required AuthService authService, this.onUnauthorized})
    : _authService = authService;

  final AuthService _authService;
  final Future<void> Function()? onUnauthorized;
  Future<void>? _unauthorizedTask;

  Future<List<FavoritoItem>> listar() async {
    try {
      final responseBody = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: Apis.favoritos,
      );
      final decoded = _decodeObject(responseBody);
      final rawFavorites = decoded['favoritos'];
      if (rawFavorites is! List) {
        throw const FormatException(
          'La respuesta de favoritos no contiene una lista válida.',
        );
      }

      final favorites = <FavoritoItem>[];
      for (final rawFavorite in rawFavorites) {
        if (rawFavorite is! Map<String, dynamic>) {
          throw const FormatException(
            'La respuesta de favoritos contiene un registro no válido.',
          );
        }
        final rawCompany = rawFavorite['empresa'];
        if (rawCompany is! Map<String, dynamic>) {
          throw const FormatException(
            'Un favorito no contiene una empresa válida.',
          );
        }
        if (rawCompany['activa'] == false) continue;
        favorites.add(FavoritoItem.fromJson(rawFavorite));
      }

      favorites.sort(
        (first, second) => second.fechaRegistro.compareTo(first.fechaRegistro),
      );
      return favorites;
    } on AuthApiException catch (error) {
      await _handleUnauthorizedStatus(error.statusCode);
      throw _mapApiError(error, operation: _FavoritosOperation.list);
    } on StateError {
      await _notifyUnauthorized();
      throw const FavoritosApiException(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw FavoritosApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on FormatException {
      throw const FavoritosApiException(
        message: 'El servidor devolvió datos de favoritos no válidos.',
      );
    } on SocketException {
      throw const FavoritosApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const FavoritosApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on HttpException {
      throw const FavoritosApiException(
        message: 'Ocurrió un error al consultar tus favoritos.',
      );
    }
  }

  Future<void> agregar(String empresaId) =>
      _sendCompanyRequest('POST', empresaId);

  Future<void> quitar(String empresaId) =>
      _sendCompanyRequest('DELETE', empresaId);

  Future<bool> verificar(String empresaId) async {
    _validateCompanyId(empresaId);
    try {
      final endpoint = Apis.verificarFavorito(empresaId);
      final responseBody = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: endpoint,
      );
      final decoded = _decodeObject(responseBody);
      final result = _readVerificationResult(decoded);
      if (result == null) {
        throw const FormatException(
          'La respuesta de verificación de favoritos no es válida.',
        );
      }
      return result;
    } on AuthApiException catch (error) {
      await _handleUnauthorizedStatus(error.statusCode);
      throw _mapApiError(error, operation: _FavoritosOperation.verify);
    } on StateError {
      await _notifyUnauthorized();
      throw const FavoritosApiException(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw FavoritosApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on FormatException {
      throw const FavoritosApiException(
        message: 'El servidor devolvió una verificación no válida.',
      );
    } on SocketException {
      throw const FavoritosApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const FavoritosApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on HttpException {
      throw const FavoritosApiException(
        message: 'Ocurrió un error al verificar tus favoritos.',
      );
    }
  }

  Future<void> _sendCompanyRequest(String method, String empresaId) async {
    _validateCompanyId(empresaId);
    final operation = method == 'POST'
        ? _FavoritosOperation.add
        : _FavoritosOperation.remove;
    try {
      await _authService.authenticatedRequest(
        method: method,
        endpoint: Apis.favoritoPorEmpresa(empresaId),
      );
    } on AuthApiException catch (error) {
      await _handleUnauthorizedStatus(error.statusCode);
      throw _mapApiError(error, operation: operation);
    } on StateError {
      await _notifyUnauthorized();
      throw const FavoritosApiException(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw FavoritosApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on SocketException {
      throw const FavoritosApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const FavoritosApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on HttpException {
      throw const FavoritosApiException(
        message: 'Ocurrió un error al actualizar tus favoritos.',
      );
    }
  }

  void _validateCompanyId(String empresaId) {
    if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(empresaId)) {
      throw const FavoritosApiException(
        message: 'El identificador de la empresa no es válido.',
      );
    }
  }

  Map<String, dynamic> _decodeObject(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const FormatException('La respuesta está vacía.');
    }
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta no tiene un formato válido.');
    }
    return decoded;
  }

  bool? _readVerificationResult(Map<String, dynamic> response) {
    for (final key in [
      'esFavorito',
      'esFavorita',
      'es_favorito',
      'isFavorite',
      'favorito',
      'existe',
    ]) {
      final value = response[key];
      if (value is bool) return value;
    }
    final data = response['data'];
    return data is Map<String, dynamic> ? _readVerificationResult(data) : null;
  }

  FavoritosApiException _mapApiError(
    AuthApiException error, {
    required _FavoritosOperation operation,
  }) {
    final serverMessage = error.message.trim();
    if (error.statusCode == 409 && operation == _FavoritosOperation.add) {
      return FavoritoExistenteException(
        message: serverMessage.isEmpty
            ? 'La empresa ya está en tus favoritos.'
            : serverMessage,
      );
    }
    if (error.statusCode == 404 && operation == _FavoritosOperation.add) {
      return EmpresaNoEncontradaException(
        message: serverMessage.isEmpty
            ? 'La empresa ya no está disponible.'
            : serverMessage,
      );
    }
    if (error.statusCode == 404 && operation == _FavoritosOperation.remove) {
      return FavoritoNoEncontradoException(
        message: serverMessage.isEmpty
            ? 'La empresa ya no estaba en tus favoritos.'
            : serverMessage,
      );
    }
    if (serverMessage.isNotEmpty) {
      return FavoritosApiException(
        statusCode: error.statusCode,
        message: serverMessage,
      );
    }
    final message = switch (error.statusCode) {
      401 => 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      403 => 'No tienes permiso para modificar favoritos.',
      >= 500 =>
        'El servidor no pudo completar la solicitud. Inténtalo más tarde.',
      _ =>
        'No se pudieron actualizar tus favoritos (error ${error.statusCode}).',
    };
    return FavoritosApiException(
      statusCode: error.statusCode,
      message: message,
    );
  }

  Future<void> _handleUnauthorizedStatus(int statusCode) async {
    if (statusCode == 401) await _notifyUnauthorized();
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

enum _FavoritosOperation { list, add, remove, verify }

class FavoritosApiException implements Exception {
  const FavoritosApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}

class FavoritoExistenteException extends FavoritosApiException {
  const FavoritoExistenteException({required super.message})
    : super(statusCode: 409);
}

class EmpresaNoEncontradaException extends FavoritosApiException {
  const EmpresaNoEncontradaException({required super.message})
    : super(statusCode: 404);
}

class FavoritoNoEncontradoException extends FavoritosApiException {
  const FavoritoNoEncontradoException({required super.message})
    : super(statusCode: 404);
}
