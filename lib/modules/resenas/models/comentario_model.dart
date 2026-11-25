class ResenaEstudiante {
  const ResenaEstudiante({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;

  String get nombreCompleto => [
    nombre,
    apellidoPaterno,
    apellidoMaterno,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  factory ResenaEstudiante.fromJson(Object? value) {
    if (value is String) {
      return ResenaEstudiante(
        id: value,
        nombre: '',
        apellidoPaterno: '',
        apellidoMaterno: '',
      );
    }
    if (value is! Map) {
      throw const FormatException('El estudiante de la reseña no es válido.');
    }
    final json = Map<String, dynamic>.from(value);
    final id = json['_id'] ?? json['id'];
    if (id == null) {
      throw const FormatException('El estudiante de la reseña no es válido.');
    }
    return ResenaEstudiante(
      id: id.toString(),
      nombre: _string(json['nombre']),
      apellidoPaterno: _string(json['apellidoPaterno']),
      apellidoMaterno: _string(json['apellidoMaterno']),
    );
  }
}

class ResenaEmpresa {
  const ResenaEmpresa({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory ResenaEmpresa.fromJson(Object? value) {
    if (value is String) {
      return ResenaEmpresa(id: value, nombre: '');
    }
    if (value is! Map) {
      throw const FormatException('La empresa de la reseña no es válida.');
    }
    final json = Map<String, dynamic>.from(value);
    final id = json['_id'] ?? json['id'];
    if (id == null) {
      throw const FormatException('La empresa de la reseña no es válida.');
    }
    return ResenaEmpresa(id: id.toString(), nombre: _string(json['nombre']));
  }
}

class ComentarioModel {
  const ComentarioModel({
    required this.id,
    required this.estudiante,
    required this.empresa,
    required this.comentario,
    required this.calificacion,
    required this.visible,
    required this.fechaRegistro,
  });

  final String id;
  final ResenaEstudiante estudiante;
  final ResenaEmpresa empresa;
  final String comentario;
  final int calificacion;
  final bool visible;
  final DateTime fechaRegistro;

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final rawRating = json['calificacion'];
    final rawComment = json['comentario'];
    final rawVisible = json['visible'];
    final rawDate = json['fechaRegistro'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (id == null ||
        rawRating is! num ||
        rawRating % 1 != 0 ||
        rawComment is! String ||
        rawVisible is! bool ||
        date == null) {
      throw const FormatException('La reseña no tiene un formato válido.');
    }

    return ComentarioModel(
      id: id.toString(),
      estudiante: ResenaEstudiante.fromJson(
        json['estudianteId'] ?? json['estudiante'],
      ),
      empresa: ResenaEmpresa.fromJson(json['empresaId'] ?? json['empresa']),
      comentario: rawComment,
      calificacion: rawRating.toInt(),
      visible: rawVisible,
      fechaRegistro: date,
    );
  }
}

class ComentarioListResponse {
  const ComentarioListResponse({
    required this.total,
    required this.comentarios,
  });

  final int total;
  final List<ComentarioModel> comentarios;

  factory ComentarioListResponse.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'];
    final rawComentarios = json['comentarios'];
    if (rawTotal is! num || rawTotal % 1 != 0 || rawComentarios is! List) {
      throw const FormatException(
        'La respuesta de reseñas no tiene un formato válido.',
      );
    }
    return ComentarioListResponse(
      total: rawTotal.toInt(),
      comentarios: rawComentarios
          .map((raw) {
            if (raw is! Map) {
              throw const FormatException(
                'Una reseña no tiene un formato válido.',
              );
            }
            return ComentarioModel.fromJson(Map<String, dynamic>.from(raw));
          })
          .toList(growable: false),
    );
  }
}

String _string(Object? value) => value is String ? value : '';
