class PermisoResenaModel {
  const PermisoResenaModel({
    required this.empresaId,
    required this.estadiaFinalizada,
    required this.tieneResena,
    required this.puedeCalificar,
    required this.comentarioId,
    required this.visible,
    required this.motivo,
  });

  final String empresaId;
  final bool estadiaFinalizada;
  final bool tieneResena;
  final bool puedeCalificar;
  final String? comentarioId;
  final bool? visible;
  final String? motivo;

  factory PermisoResenaModel.fromJson(Map<String, dynamic> json) {
    final empresaId = json['empresaId'];
    final estadiaFinalizada = json['estadiaFinalizada'];
    final tieneResena = json['tieneResena'];
    final puedeCalificar = json['puedeCalificar'];
    final comentarioId = json['comentarioId'];
    final visible = json['visible'];
    final motivo = json['motivo'];
    if (empresaId == null ||
        estadiaFinalizada is! bool ||
        tieneResena is! bool ||
        puedeCalificar is! bool ||
        (comentarioId != null && comentarioId is! String) ||
        (visible != null && visible is! bool) ||
        (motivo != null && motivo is! String)) {
      throw const FormatException(
        'La respuesta de permisos de reseña no es válida.',
      );
    }
    return PermisoResenaModel(
      empresaId: empresaId.toString(),
      estadiaFinalizada: estadiaFinalizada,
      tieneResena: tieneResena,
      puedeCalificar: puedeCalificar,
      comentarioId: comentarioId as String?,
      visible: visible as bool?,
      motivo: motivo as String?,
    );
  }
}
