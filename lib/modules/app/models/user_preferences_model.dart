class UserPreferencesModel {
  const UserPreferencesModel({
    this.academicLevel,
    this.employmentTypes = const [],
    this.specializations = const [],
    this.modalities = const [],
    this.location,
  });

  final String? academicLevel;
  final List<String> employmentTypes;
  final List<String> specializations;
  final List<String> modalities;
  final String? location;

  Map<String, dynamic> toJson() => {
    'nivel': academicLevel,
    'tiposEmpleo': employmentTypes,
    'especializaciones': specializations,
    'modalidades': modalities,
    'ubicacion': location,
  };

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      academicLevel: json['nivel'] as String?,
      employmentTypes: _stringList(json['tiposEmpleo']),
      specializations: _stringList(json['especializaciones']),
      modalities: _stringList(json['modalidades']),
      location: json['ubicacion'] as String?,
    );
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];
}
