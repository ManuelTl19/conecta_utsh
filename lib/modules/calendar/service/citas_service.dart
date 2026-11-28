import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';
import 'dart:io';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/calendar/models/appointment_model.dart';
import 'package:conecta_utsh/modules/calendar/models/availability_model.dart';

class OpcionAcademicaModel {
  const OpcionAcademicaModel({
    required this.direccion,
    required this.carreras,
    required this.diasSemana,
    required this.bloquesPorDia,
    required this.duracionMinutos,
  });

  final String direccion;
  final core.List<String> carreras;
  final core.List<String> diasSemana;
  final core.List<core.Map<String, dynamic>> bloquesPorDia;
  final int duracionMinutos;

  factory OpcionAcademicaModel.fromJson(core.Map<String, dynamic> json) {
    return OpcionAcademicaModel(
      direccion: json['direccion']?.toString() ?? '',
      carreras: (json['carreras'] as core.List? ?? [])
          .map((e) => e.toString())
          .toList(),
      diasSemana: (json['diasSemana'] as core.List? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toList(),
      bloquesPorDia: (json['bloquesPorDia'] as core.List? ?? [])
          .map((e) => core.Map<String, dynamic>.from(e as core.Map))
          .toList(),
      duracionMinutos: (json['duracionMinutos'] as num?)?.toInt() ?? 10,
    );
  }

  String get descripcionHorario {
    if (bloquesPorDia.isEmpty) return 'Sin horarios configurados.';
    final partes = bloquesPorDia.map((item) {
      final dia = item['dia']?.toString() ?? '';
      final diaCapitalizado = dia.isEmpty
          ? ''
          : '${dia[0].toUpperCase()}${dia.substring(1)}';
      final bloques = (item['bloques'] as core.List? ?? [])
          .map((b) => '${b['inicio']} a ${b['fin']} h')
          .join(' y ');
      return '$diaCapitalizado ($bloques)';
    }).join(' · ');
    return 'Atención: $partes · citas de $duracionMinutos min';
  }
}

class CitasService {
  CitasService({
    Uri? citasEndpoint,
    Uri? horariosDisponiblesEndpoint,
    HttpClient? client,
    TokenStore? tokenStore,
  }) : _citasEndpoint = citasEndpoint ?? Apis.citas,
       _horariosDisponiblesEndpoint =
           horariosDisponiblesEndpoint ?? Apis.horariosDisponibles,
       _client = client ?? HttpClient(),
       _tokenStore = tokenStore ?? SecureTokenStore();

  final Uri _citasEndpoint;
  final Uri _horariosDisponiblesEndpoint;
  final HttpClient _client;
  final TokenStore _tokenStore;

  Future<List<OpcionAcademicaModel>> obtenerOpcionesAcademicas() async {
    final response = await _request('GET', _uri('opciones-academicas'));
    final decoded = _decodeJson(response);
    final opciones =
        decoded is Map<String, dynamic> && decoded['opciones'] is List
        ? decoded['opciones'] as List
        : throw const FormatException(
            'La respuesta de opciones académicas no es válida.',
          );

    return opciones
        .map((item) => OpcionAcademicaModel.fromJson(_asObject(item)))
        .toList();
  }

  Future<List<AppointmentModel>> obtenerCitas() =>
      _obtenerCitasDesde(_citasEndpoint);

  Future<List<AppointmentModel>> obtenerMisCitas() =>
      _obtenerCitasDesde(_uri('mis-citas'));

  Future<List<AppointmentModel>> _obtenerCitasDesde(Uri endpoint) async {
    final response = await _request('GET', endpoint);
    final decoded = _decodeJson(response);
    final citas = decoded is List
        ? decoded
        : decoded is Map<String, dynamic> && decoded['citas'] is List
        ? decoded['citas'] as List
        : throw const FormatException('La respuesta de citas no es válida.');

    return citas
        .map((cita) => AppointmentModel.fromJson(_asObject(cita)))
        .toList();
  }

  Future<AppointmentModel> obtenerCitaPorId(String id) async {
    final response = await _request('GET', _uri(Uri.encodeComponent(id)));
    return AppointmentModel.fromJson(_responseObject(response));
  }

  Future<AppointmentModel> crearCita({
    required DateTime fechaHora,
    required String motivo,
    String? direccion,
    String? carrera,
  }) async {
    final response = await _request(
      'POST',
      _citasEndpoint,
      body: {
        'fechaHora': fechaHora.toUtc().toIso8601String(),
        'motivo': motivo,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
        if (carrera != null && carrera.isNotEmpty) 'carrera': carrera,
      },
    );
    return AppointmentModel.fromJson(_responseObject(response));
  }

  Future<AvailableDateModel> obtenerHorariosDisponibles(
    DateTime fecha, {
    String? direccion,
    String? carrera,
  }) async {
    final fechaLocal =
        '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    final queryParams = <String, String>{
      'fecha': fechaLocal,
      if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      if (carrera != null && carrera.isNotEmpty) 'carrera': carrera,
    };
    final endpoint = _horariosDisponiblesEndpoint.replace(
      queryParameters: queryParams,
    );
    final response = await _request('GET', endpoint);
    final decoded = _decodeJson(response);
    final payload = decoded is Map<String, dynamic> && decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;

    if (payload is List) {
      return AvailableDateModel.fromJson({
        'fecha': fechaLocal,
        'horarios': payload,
      });
    }
    if (payload is Map<String, dynamic>) {
      return AvailableDateModel.fromJson({
        ...payload,
        'fecha': payload['fecha'] ?? payload['date'] ?? fechaLocal,
      });
    }
    throw const FormatException(
      'La respuesta de horarios disponibles no es válida.',
    );
  }

  Future<AppointmentModel> actualizarCita(
    String id, {
    DateTime? fechaHora,
    int? duracionMinutos,
    String? motivo,
  }) async {
    final body = <String, dynamic>{
      if (fechaHora != null)
        'fechaHora': fechaHora.toUtc().toIso8601String(),
      if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
      if (motivo != null) 'motivo': motivo,
    };
    if (body.isEmpty) {
      throw ArgumentError(
        'Debes proporcionar al menos un campo para actualizar.',
      );
    }

    final response = await _request(
      'PATCH',
      _uri(Uri.encodeComponent(id)),
      body: body,
    );
    return AppointmentModel.fromJson(_responseObject(response));
  }

  Future<AppointmentModel> actualizarEstadoCita(
    String id, {
    String? estado,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{
      if (estado != null) 'estado': estado,
      if (observaciones != null) 'observaciones': observaciones,
    };
    if (body.isEmpty) {
      throw ArgumentError('Debes proporcionar estado u observaciones.');
    }

    final response = await _request(
      'PATCH',
      _uri('${Uri.encodeComponent(id)}/estado'),
      body: body,
    );
    return AppointmentModel.fromJson(_responseObject(response));
  }

  Future<AppointmentModel> cancelarCita(String id) async {
    final response = await _request(
      'PATCH',
      _uri('${Uri.encodeComponent(id)}/cancelar'),
    );
    return AppointmentModel.fromJson(_responseObject(response));
  }

  Uri _uri(String suffix) => _citasEndpoint.replace(
    path: '${_citasEndpoint.path.replaceFirst(RegExp(r'/$'), '')}/$suffix',
  );

  Future<String> _request(
    String method,
    Uri endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw StateError('No hay una sesión activa para esta solicitud.');
    }

    final request = await _client
        .openUrl(method, endpoint)
        .timeout(const Duration(seconds: 15));
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(
      const Duration(seconds: 15),
    );
    final responseBody = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CitaApiException(
        statusCode: response.statusCode,
        message: _errorMessage(responseBody) ?? response.reasonPhrase,
      );
    }
    return responseBody;
  }

  String? _errorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map) return decoded['message']?.toString();
    } on FormatException {
      return null;
    }
    return null;
  }

  dynamic _decodeJson(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const FormatException('El servidor devolvió una respuesta vacía.');
    }
    return jsonDecode(responseBody);
  }

  Map<String, dynamic> _responseObject(String responseBody) {
    final decoded = _decodeJson(responseBody);
    final object = decoded is Map<String, dynamic> && decoded['cita'] is Map
        ? decoded['cita']
        : decoded;
    return _asObject(object);
  }

  Map<String, dynamic> _asObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('La cita devuelta por el servidor no es válida.');
  }

  void close() => _client.close();
}

class CitaApiException implements Exception {
  const CitaApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String? message;

  @override
  String toString() =>
      'CitaApiException($statusCode): ${message ?? 'Error al procesar la cita.'}';
}