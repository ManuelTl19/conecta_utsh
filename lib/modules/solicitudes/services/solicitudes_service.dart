import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_model.dart';

class SolicitudesService {
  SolicitudesService({required this.authService, this.onUnauthorized});

  final AuthService authService;
  final Future<void> Function()? onUnauthorized;
  Future<void>? _unauthorizedTask;

  Future<SolicitudCollectionModel> misSolicitudes() => _execute(() async {
    final response = await _request('GET', Apis.misSolicitudes);
    return SolicitudCollectionModel.fromJson(
      _decodeMap(response),
      requireSummary: true,
    );
  });

  Future<SolicitudCollectionModel> listar({
    SolicitudEstado? estado,
    SolicitudOrigen? origen,
    String? estudianteId,
    String? empresaId,
  }) => _execute(() async {
    final query = <String, String>{};
    if (estado != null) query['estado'] = estado.valor;
    if (origen != null) query['origen'] = origen.valor;
    final studentFilter = estudianteId?.trim();
    if (studentFilter != null && studentFilter.isNotEmpty) {
      query['estudianteId'] = studentFilter;
    }
    final companyFilter = empresaId?.trim();
    if (companyFilter != null && companyFilter.isNotEmpty) {
      query['empresaId'] = companyFilter;
    }
    final endpoint = query.isEmpty
        ? Apis.solicitudes
        : Apis.solicitudes.replace(queryParameters: query);
    final response = await _request('GET', endpoint);
    return SolicitudCollectionModel.fromJson(_decodeMap(response));
  });

  Future<SolicitudModel> obtenerPorId(String solicitudId) => _execute(() async {
    final response = await _request('GET', Apis.solicitud(solicitudId));
    final decoded = _decodeMap(response);
    final rawRequest = decoded['solicitud'];
    if (rawRequest is! Map) {
      throw const FormatException(
        'La respuesta no contiene una solicitud válida.',
      );
    }
    return SolicitudModel.fromJson(Map<String, dynamic>.from(rawRequest));
  });

  Future<SolicitudMutationResult> crear({
    required String empresaId,
    required SolicitudOrigen origen,
    String? estudianteId,
  }) => _execute(() async {
    final requestBody = <String, dynamic>{
      'empresaId': empresaId,
      'origen': origen.valor,
    };
    final normalizedStudentId = estudianteId?.trim();
    if (normalizedStudentId != null && normalizedStudentId.isNotEmpty) {
      requestBody['estudianteId'] = normalizedStudentId;
    }
    final response = await _request(
      'POST',
      Apis.solicitudes,
      body: requestBody,
    );
    return SolicitudMutationResult.fromJson(_decodeMap(response));
  });

  Future<SolicitudMutationResult> cambiarEstado({
    required String solicitudId,
    SolicitudEstado? estado,
    String? observaciones,
  }) => _execute(() async {
    if (estado == null && observaciones == null) {
      throw const SolicitudesApiException(
        statusCode: HttpStatus.badRequest,
        message: 'Envía el estado o las observaciones',
      );
    }
    if (observaciones != null && observaciones.length > 2000) {
      throw const SolicitudesApiException(
        statusCode: HttpStatus.badRequest,
        message: 'Las observaciones deben ser texto de máximo 2000 caracteres',
      );
    }
    final body = <String, dynamic>{};
    if (estado != null) body['estado'] = estado.valor;
    if (observaciones != null) body['observaciones'] = observaciones;
    final response = await _request(
      'PATCH',
      Apis.estadoSolicitud(solicitudId),
      body: body,
    );
    return SolicitudMutationResult.fromJson(_decodeMap(response));
  });

  Future<SolicitudMutationResult> cancelar(String solicitudId) =>
      _execute(() async {
        final response = await _request('DELETE', Apis.solicitud(solicitudId));
        return SolicitudMutationResult.fromJson(_decodeMap(response));
      });

  Future<T> _execute<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthApiException catch (error) {
      if (error.statusCode == HttpStatus.unauthorized) {
        await _notifyUnauthorized();
      }
      final message = error.message.trim();
      throw SolicitudesApiException(
        statusCode: error.statusCode,
        message: message.isNotEmpty
            ? message
            : 'No se pudo completar la solicitud.',
      );
    } on StateError {
      await _notifyUnauthorized();
      throw const SolicitudesApiException(
        statusCode: HttpStatus.unauthorized,
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw SolicitudesApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on SocketException {
      throw const SolicitudesApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const SolicitudesApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on FormatException {
      throw const SolicitudesApiException(
        message: 'El servidor devolvió datos de solicitudes no válidos.',
      );
    } on HttpException {
      throw const SolicitudesApiException(
        message: 'Ocurrió un error al consultar las solicitudes.',
      );
    }
  }

  Future<String> _request(
    String method,
    Uri endpoint, {
    Map<String, dynamic>? body,
  }) => authService.authenticatedRequest(
    method: method,
    endpoint: endpoint,
    body: body,
  );

  Map<String, dynamic> _decodeMap(String response) {
    if (response.trim().isEmpty) {
      throw const FormatException('La respuesta del servidor está vacía.');
    }
    final decoded = jsonDecode(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es válida.');
    }
    return decoded;
  }

  Future<void> _notifyUnauthorized() async {
    final callback = onUnauthorized;
    if (callback == null) return;
    final activeTask = _unauthorizedTask;
    if (activeTask != null) return activeTask;
    final task = Future<void>.sync(callback);
    _unauthorizedTask = task;
    try {
      await task;
    } finally {
      _unauthorizedTask = null;
    }
  }
}

class SolicitudesApiException implements Exception {
  const SolicitudesApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
