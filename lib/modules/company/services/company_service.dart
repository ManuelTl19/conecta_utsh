import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class CompanyService {
  CompanyService({
    required AuthService authService,
    this.onUnauthorized,
    Uri? endpoint,
  }) : _authService = authService,
       _endpoint = endpoint ?? Apis.companies;

  final AuthService _authService;
  final Future<void> Function()? onUnauthorized;
  final Uri _endpoint;
  Future<void>? _unauthorizedTask;

  Future<CompanyListResponse> getCompanies({
    String? empresa,
    String? direccionAcademica,
    String? carrera,
    String? estado,
    String? municipio,
    bool soloFavoritas = false,
  }) async {
    final queryParameters = <String, String>{};
    _addQueryParameter(queryParameters, 'empresa', empresa);
    _addQueryParameter(
      queryParameters,
      'direccionAcademica',
      direccionAcademica,
    );
    _addQueryParameter(queryParameters, 'carrera', carrera);
    _addQueryParameter(queryParameters, 'estado', estado);
    _addQueryParameter(queryParameters, 'municipio', municipio);
    if (soloFavoritas) queryParameters['favoritos'] = 'true';

    final endpoint = queryParameters.isEmpty
        ? _endpoint
        : _endpoint.replace(queryParameters: queryParameters);

    try {
      final responseBody = await _authService.authenticatedRequest(
        method: 'GET',
        endpoint: endpoint,
      );
      if (responseBody.trim().isEmpty) {
        throw const FormatException('La respuesta de empresas está vacía.');
      }
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'La respuesta de empresas no tiene un formato válido.',
        );
      }
      return CompanyListResponse.fromJson(decoded);
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) await _notifyUnauthorized();
      throw CompanyApiException(
        statusCode: error.statusCode,
        message: error.message.trim().isNotEmpty
            ? error.message
            : _messageForStatus(error.statusCode),
      );
    } on StateError {
      await _notifyUnauthorized();
      throw const CompanyApiException(
        message: 'Tu sesión ha expirado. Inicia sesión de nuevo.',
      );
    } on TokenStorageException catch (error) {
      throw CompanyApiException(
        message: 'No se pudo acceder a tu sesión: ${error.message}',
      );
    } on FormatException {
      throw const CompanyApiException(
        message: 'El servidor devolvió datos de empresas no válidos.',
      );
    } on SocketException {
      throw const CompanyApiException(
        message: 'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on TimeoutException {
      throw const CompanyApiException(
        message: 'La solicitud tardó demasiado. Inténtalo de nuevo.',
      );
    } on HttpException {
      throw const CompanyApiException(
        message: 'Ocurrió un error al consultar las empresas.',
      );
    }
  }

  void _addQueryParameter(
    Map<String, String> parameters,
    String key,
    String? value,
  ) {
    final trimmedValue = value?.trim();
    if (trimmedValue != null && trimmedValue.isNotEmpty) {
      parameters[key] = trimmedValue;
    }
  }

  String _messageForStatus(int statusCode) {
    if (statusCode == 400) {
      return 'Los filtros enviados no son válidos.';
    }
    if (statusCode >= 400 && statusCode < 500) {
      return 'No se pudieron consultar las empresas (error $statusCode).';
    }
    if (statusCode >= 500) {
      return 'El servidor no pudo completar la solicitud. Inténtalo más tarde.';
    }
    return 'No se pudieron consultar las empresas.';
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

class CompanyApiException implements Exception {
  const CompanyApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
