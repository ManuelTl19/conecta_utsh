import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/resenas/models/comentario_model.dart';
import 'package:conecta_utsh/modules/resenas/models/permiso_resena_model.dart';
import 'package:conecta_utsh/modules/resenas/models/resumen_model.dart';

class ResenasService {
  ResenasService({required this.authService, this.onUnauthorized});

  final AuthService authService;
  final Future<void> Function()? onUnauthorized;
  Future<void>? _unauthorizedTask;

  Future<ComentarioListResponse> listar({
    required String empresaId,
    bool? visible,
  }) => _execute(() async {
    final endpoint = visible == null
        ? Apis.comentariosEmpresa(empresaId)
        : Apis.comentarios.replace(
            queryParameters: {
              'empresaId': empresaId,
              'visible': visible.toString(),
            },
          );
    final body = await _request(method: 'GET', endpoint: endpoint);
    return ComentarioListResponse.fromJson(_decodeObject(body));
  });

  Future<ResumenModel> resumen(String empresaId) => _execute(() async {
    final body = await _request(
      method: 'GET',
      endpoint: Apis.resumenComentarios(empresaId),
    );
    return ResumenModel.fromJson(_decodeObject(body));
  });

  Future<PermisoResenaModel> puedeCalificar(String empresaId) =>
      _execute(() async {
        final body = await _request(
          method: 'GET',
          endpoint: Apis.permisoComentario(empresaId),
        );
        return PermisoResenaModel.fromJson(_decodeObject(body));
      });

  Future<ComentarioModel> miComentario(String empresaId) => _execute(() async {
    final body = await _request(
      method: 'GET',
      endpoint: Apis.miComentario(empresaId),
    );
    final decoded = _decodeObject(body);
    final rawComment = decoded['comentario'] ?? decoded;
    if (rawComment is! Map) {
      throw const FormatException(
        'La reseña propia no tiene un formato válido.',
      );
    }
    return ComentarioModel.fromJson(Map<String, dynamic>.from(rawComment));
  });

  Future<ComentarioModel> crear({
    required String empresaId,
    required int calificacion,
    required String comentario,
  }) => _execute(() async {
    _validateInput(calificacion, comentario);
    final body = await _request(
      method: 'POST',
      endpoint: Apis.comentarios,
      body: {
        'empresaId': empresaId,
        'calificacion': calificacion,
        'comentario': comentario,
      },
    );
    return _commentFromMutation(body);
  });

  Future<ComentarioModel> actualizar({
    required String comentarioId,
    required int calificacion,
    required String comentario,
  }) => _execute(() async {
    _validateInput(calificacion, comentario);
    final body = await _request(
      method: 'PATCH',
      endpoint: Apis.comentario(comentarioId),
      body: {'comentario': comentario, 'calificacion': calificacion},
    );
    return _commentFromMutation(body);
  });

  Future<ComentarioModel> moderar({
    required String comentarioId,
    required bool visible,
  }) => _execute(() async {
    final body = await _request(
      method: 'PATCH',
      endpoint: Apis.comentario(comentarioId),
      body: {'visible': visible},
    );
    return _commentFromMutation(body);
  });

  Future<void> eliminar(String comentarioId) => _execute(() async {
    await _request(method: 'DELETE', endpoint: Apis.comentario(comentarioId));
  });

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) await _notifyUnauthorized();
      throw ResenasApiException(
        statusCode: error.statusCode,
        message: error.message.trim().isNotEmpty
            ? error.message
            : 'No se pudo completar la solicitud de reseñas.',
      );
    } on StateError {
      await _notifyUnauthorized();
      throw const ResenasApiException(
        statusCode: 401,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw ResenasApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on FormatException {
      throw const ResenasApiException(
        message: 'El servidor devolvió datos de reseñas no válidos.',
      );
    } on SocketException {
      throw const ResenasApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const ResenasApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on HttpException {
      throw const ResenasApiException(
        message: 'Ocurrió un error al consultar las reseñas.',
      );
    }
  }

  Future<String> _request({
    required String method,
    required Uri endpoint,
    Map<String, dynamic>? body,
  }) => authService.authenticatedRequest(
    method: method,
    endpoint: endpoint,
    body: body,
  );

  ComentarioModel _commentFromMutation(String body) {
    final decoded = _decodeObject(body);
    final rawComment = decoded['comentario'];
    if (rawComment is! Map) {
      throw const FormatException(
        'La respuesta de la operación no contiene una reseña válida.',
      );
    }
    return ComentarioModel.fromJson(Map<String, dynamic>.from(rawComment));
  }

  Map<String, dynamic> _decodeObject(String body) {
    if (body.trim().isEmpty) {
      throw const FormatException('La respuesta del servidor está vacía.');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es válida.');
    }
    return decoded;
  }

  void _validateInput(int calificacion, String comentario) {
    if (calificacion < 1 || calificacion > 5) {
      throw const ResenasApiException(
        statusCode: 400,
        message: 'La calificación debe ser un entero de 1 a 5.',
      );
    }
    if (comentario.length > 1000) {
      throw const ResenasApiException(
        statusCode: 400,
        message: 'El comentario no puede superar los 1000 caracteres.',
      );
    }
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

class ResenasApiException implements Exception {
  const ResenasApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
