class CompanyFilters {
  const CompanyFilters({
    this.direccion,
    this.carreras = const [],
    this.estado,
    this.municipio,
    this.calificacionMin,
    this.soloFavoritas = false,
  });

  final String? direccion;
  final List<String> carreras;
  final String? estado;
  final String? municipio;
  final double? calificacionMin;
  final bool soloFavoritas;

  bool get hasActiveFilters =>
      direccion != null ||
      carreras.isNotEmpty ||
      estado != null ||
      municipio != null ||
      calificacionMin != null ||
      soloFavoritas;

  CompanyFilters copyWith({
    String? direccion,
    bool clearDireccion = false,
    List<String>? carreras,
    String? estado,
    bool clearEstado = false,
    String? municipio,
    bool clearMunicipio = false,
    double? calificacionMin,
    bool clearCalificacionMin = false,
    bool? soloFavoritas,
  }) => CompanyFilters(
    direccion: clearDireccion ? null : direccion ?? this.direccion,
    carreras: carreras ?? this.carreras,
    estado: clearEstado ? null : estado ?? this.estado,
    municipio: clearMunicipio ? null : municipio ?? this.municipio,
    calificacionMin: clearCalificacionMin
        ? null
        : calificacionMin ?? this.calificacionMin,
    soloFavoritas: soloFavoritas ?? this.soloFavoritas,
  );
}

class CompanyFilterOptions {
  const CompanyFilterOptions({
    required this.estados,
    required this.municipiosPorEstado,
  });

  final List<String> estados;
  final Map<String, List<String>> municipiosPorEstado;

  List<String> municipiosDe(String? estado) =>
      estado == null ? const [] : municipiosPorEstado[estado] ?? const [];
}
