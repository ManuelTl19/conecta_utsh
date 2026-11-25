class CompanyFilters {
  const CompanyFilters({
    this.direccionAcademica,
    this.carrera,
    this.estado,
    this.municipio,
    this.soloFavoritas = false,
  });

  final String? direccionAcademica;
  final String? carrera;
  final String? estado;
  final String? municipio;
  final bool soloFavoritas;

  bool get hasActiveFilters =>
      direccionAcademica != null ||
      carrera != null ||
      estado != null ||
      municipio != null ||
      soloFavoritas;

  CompanyFilters copyWith({
    String? direccionAcademica,
    bool clearDireccionAcademica = false,
    String? carrera,
    bool clearCarrera = false,
    String? estado,
    bool clearEstado = false,
    String? municipio,
    bool clearMunicipio = false,
    bool? soloFavoritas,
  }) => CompanyFilters(
    direccionAcademica: clearDireccionAcademica
        ? null
        : direccionAcademica ?? this.direccionAcademica,
    carrera: clearCarrera ? null : carrera ?? this.carrera,
    estado: clearEstado ? null : estado ?? this.estado,
    municipio: clearMunicipio ? null : municipio ?? this.municipio,
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
