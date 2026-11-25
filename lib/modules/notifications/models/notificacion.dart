class Notificacion {
  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fechaLectura,
    required this.fechaRegistro,
    this.referenciaId,
    this.referenciaModelo,
  });

  static const _notProvided = Object();

  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String? referenciaId;
  final String? referenciaModelo;
  final bool leida;
  final DateTime? fechaLectura;
  final DateTime fechaRegistro;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final usuarioId = json['usuarioId'];
    final titulo = json['titulo'];
    final mensaje = json['mensaje'];
    final tipo = json['tipo'];
    final leida = json['leida'];
    final fechaRegistro = json['fechaRegistro'];
    final fechaLectura = json['fechaLectura'];
    final referenciaId = json['referenciaId'];
    final referenciaModelo = json['referenciaModelo'];

    if (id is! String ||
        usuarioId is! String ||
        titulo is! String ||
        mensaje is! String ||
        tipo is! String ||
        leida is! bool ||
        fechaRegistro is! String ||
        (fechaLectura != null && fechaLectura is! String) ||
        (referenciaId != null && referenciaId is! String) ||
        (referenciaModelo != null && referenciaModelo is! String)) {
      throw const FormatException(
        'Los datos de la notificación no son válidos.',
      );
    }

    return Notificacion(
      id: id,
      usuarioId: usuarioId,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      referenciaId: referenciaId as String?,
      referenciaModelo: referenciaModelo as String?,
      leida: leida,
      fechaLectura: fechaLectura == null
          ? null
          : DateTime.parse(fechaLectura as String),
      fechaRegistro: DateTime.parse(fechaRegistro),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'usuarioId': usuarioId,
    'titulo': titulo,
    'mensaje': mensaje,
    'tipo': tipo,
    'referenciaId': referenciaId,
    'referenciaModelo': referenciaModelo,
    'leida': leida,
    'fechaLectura': fechaLectura?.toIso8601String(),
    'fechaRegistro': fechaRegistro.toIso8601String(),
  };

  Notificacion copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? mensaje,
    String? tipo,
    Object? referenciaId = _notProvided,
    Object? referenciaModelo = _notProvided,
    bool? leida,
    Object? fechaLectura = _notProvided,
    DateTime? fechaRegistro,
  }) => Notificacion(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    titulo: titulo ?? this.titulo,
    mensaje: mensaje ?? this.mensaje,
    tipo: tipo ?? this.tipo,
    referenciaId: identical(referenciaId, _notProvided)
        ? this.referenciaId
        : referenciaId as String?,
    referenciaModelo: identical(referenciaModelo, _notProvided)
        ? this.referenciaModelo
        : referenciaModelo as String?,
    leida: leida ?? this.leida,
    fechaLectura: identical(fechaLectura, _notProvided)
        ? this.fechaLectura
        : fechaLectura as DateTime?,
    fechaRegistro: fechaRegistro ?? this.fechaRegistro,
  );
}
