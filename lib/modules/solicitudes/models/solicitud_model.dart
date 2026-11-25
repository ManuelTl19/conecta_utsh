import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/solicitudes/models/solicitud_estado.dart';
import 'package:conecta_utsh/modules/solicitudes/models/resumen_solicitudes_model.dart';

class SolicitudPersona {
  const SolicitudPersona({
    required this.id,
    this.nombre = '',
    this.apellidoPaterno = '',
    this.apellidoMaterno = '',
    this.rol,
    this.matricula,
    this.direccion,
    this.carrera,
    this.cuatrimestre,
    this.correo,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String? rol;
  final String? matricula;
  final String? direccion;
  final String? carrera;
  final String? cuatrimestre;
  final String? correo;

  String get nombreCompleto => [
    nombre,
    apellidoPaterno,
    apellidoMaterno,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  factory SolicitudPersona.fromJson(Object? value) {
    if (value is String) return SolicitudPersona(id: value);
    if (value is! Map) {
      throw const FormatException('La persona de la solicitud no es válida.');
    }
    final json = Map<String, dynamic>.from(value);
    final id = json['_id'] ?? json['id'];
    if (id == null) {
      throw const FormatException('La persona de la solicitud no es válida.');
    }
    return SolicitudPersona(
      id: id.toString(),
      nombre: _string(json['nombre']) ?? '',
      apellidoPaterno: _string(json['apellidoPaterno']) ?? '',
      apellidoMaterno: _string(json['apellidoMaterno']) ?? '',
      rol: _string(json['rol']),
      matricula: _displayString(json['matricula']),
      direccion: _string(json['direccion']),
      carrera: _string(json['carrera']),
      cuatrimestre: _displayString(json['cuatrimestre']),
      correo: _string(json['correo']),
    );
  }
}

class SolicitudModel {
  const SolicitudModel({
    required this.id,
    required this.estudiante,
    required this.empresa,
    required this.estado,
    required this.observaciones,
    required this.fechaRegistro,
    required this.fechaActualizacion,
    this.registradoPor,
    this.origen,
  });

  final String id;
  final SolicitudPersona estudiante;
  final CompanyModel empresa;
  final SolicitudPersona? registradoPor;
  final SolicitudOrigen? origen;
  final SolicitudEstado estado;
  final String observaciones;
  final DateTime fechaRegistro;
  final DateTime fechaActualizacion;

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final rawCompany = json['empresaId'] ?? json['empresa'];
    final rawStudent = json['estudianteId'] ?? json['estudiante'];
    final rawRegistrar = json['registradoPor'];
    final rawObservations = json['observaciones'];
    final registeredAt = _date(json['fechaRegistro']);
    final updatedAt = _date(json['fechaActualizacion']);
    if (id == null ||
        rawCompany == null ||
        rawStudent == null ||
        (rawRegistrar != null &&
            rawRegistrar is! String &&
            rawRegistrar is! Map) ||
        (rawObservations != null && rawObservations is! String) ||
        registeredAt == null ||
        updatedAt == null) {
      throw const FormatException('La solicitud no tiene un formato válido.');
    }

    return SolicitudModel(
      id: id.toString(),
      estudiante: SolicitudPersona.fromJson(rawStudent),
      empresa: _companyFromJson(rawCompany),
      registradoPor: rawRegistrar == null
          ? null
          : SolicitudPersona.fromJson(rawRegistrar),
      origen: SolicitudOrigen.parse(json['origen']),
      estado: SolicitudEstado.parse(json['estado']),
      observaciones: rawObservations as String? ?? '',
      fechaRegistro: registeredAt,
      fechaActualizacion: updatedAt,
    );
  }

  static CompanyModel _companyFromJson(Object value) {
    if (value is String) return CompanyModel(id: value);
    if (value is Map) {
      return CompanyModel.fromJson(Map<String, dynamic>.from(value));
    }
    throw const FormatException('La empresa de la solicitud no es válida.');
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class SolicitudCollectionModel {
  const SolicitudCollectionModel({
    required this.total,
    required this.solicitudes,
    this.resumen,
  });

  final int total;
  final List<SolicitudModel> solicitudes;
  final ResumenSolicitudesModel? resumen;

  factory SolicitudCollectionModel.fromJson(
    Map<String, dynamic> json, {
    bool requireSummary = false,
  }) {
    final total = _intValue(json['total']);
    final rawRequests = json['solicitudes'];
    final rawSummary = json['resumen'];
    if (total == null ||
        rawRequests is! List ||
        (requireSummary && rawSummary is! Map)) {
      throw const FormatException(
        'La respuesta de solicitudes no tiene un formato válido.',
      );
    }
    return SolicitudCollectionModel(
      total: total,
      solicitudes: rawRequests
          .map((raw) {
            if (raw is! Map) {
              throw const FormatException(
                'Una solicitud no tiene un formato válido.',
              );
            }
            return SolicitudModel.fromJson(Map<String, dynamic>.from(raw));
          })
          .toList(growable: false),
      resumen: rawSummary is Map
          ? ResumenSolicitudesModel.fromJson(
              Map<String, dynamic>.from(rawSummary),
            )
          : null,
    );
  }
}

class SolicitudMutationResult {
  const SolicitudMutationResult({
    required this.message,
    required this.totalCanceladas,
  });

  final String message;
  final int totalCanceladas;

  factory SolicitudMutationResult.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    final rawRequest = json['solicitud'];
    final rawCancelled = json['totalCanceladas'];
    final cancelled = rawCancelled == null ? 0 : _intValue(rawCancelled);
    if (message is! String || rawRequest is! Map || cancelled == null) {
      throw const FormatException(
        'La respuesta de la solicitud no tiene un formato válido.',
      );
    }
    return SolicitudMutationResult(
      message: message,
      totalCanceladas: cancelled,
    );
  }
}

int? _intValue(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

String? _string(Object? value) => value is String ? value : null;

String? _displayString(Object? value) =>
    value is String || value is num ? value.toString() : null;
