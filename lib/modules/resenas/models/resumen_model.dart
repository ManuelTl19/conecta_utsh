class ResumenModel {
  const ResumenModel({
    required this.empresaId,
    required this.promedio,
    required this.totalCalificaciones,
    required this.distribucion,
  });

  final String empresaId;
  final double promedio;
  final int totalCalificaciones;
  final Map<int, int> distribucion;

  factory ResumenModel.fromJson(Map<String, dynamic> json) {
    final rawEmpresaId = json['empresaId'];
    final rawPromedio = json['promedio'];
    final rawTotal = json['totalCalificaciones'];
    final rawDistribution = json['distribucion'];
    if (rawEmpresaId == null ||
        rawPromedio is! num ||
        rawTotal is! num ||
        rawTotal % 1 != 0 ||
        rawDistribution is! Map) {
      throw const FormatException(
        'El resumen de calificaciones no tiene un formato válido.',
      );
    }

    final distribution = <int, int>{};
    for (var rating = 1; rating <= 5; rating++) {
      final value = rawDistribution[rating.toString()];
      if (value is! num || value % 1 != 0) {
        throw const FormatException(
          'La distribución de calificaciones no es válida.',
        );
      }
      distribution[rating] = value.toInt();
    }
    return ResumenModel(
      empresaId: rawEmpresaId.toString(),
      promedio: rawPromedio.toDouble(),
      totalCalificaciones: rawTotal.toInt(),
      distribucion: Map.unmodifiable(distribution),
    );
  }
}
