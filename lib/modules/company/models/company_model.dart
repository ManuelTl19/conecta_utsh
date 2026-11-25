class CompanyModel {
  const CompanyModel({
    this.id = '',
    this.name,
    this.description,
    this.sector,
    this.imageUrl,
    this.availableAreas = const [],
    this.location = const CompanyLocation(),
    this.contact = const CompanyContact(),
    this.requirements = const [],
    this.active = false,
    this.registeredAt,
    this.acceptedAcademicDirections = const [],
    this.acceptedCareers = const [],
  });

  final String id;
  final String? name;
  final String? description;
  final String? sector;
  final String? imageUrl;
  final List<String> availableAreas;
  final CompanyLocation location;
  final CompanyContact contact;
  final List<String> requirements;
  final bool active;
  final DateTime? registeredAt;
  final List<String> acceptedAcademicDirections;
  final List<String> acceptedCareers;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final location = json['ubicacion'];
    final contact = json['contacto'];
    final registeredAt = json['fechaRegistro'];

    return CompanyModel(
      id: _string(json['_id']) ?? '',
      name: _string(json['nombre']),
      description: _string(json['descripcion']),
      sector: _string(json['sector']),
      imageUrl: _imageUrl(json['imagen']),
      availableAreas: _stringList(json['areasDisponibles']),
      location: CompanyLocation.fromJson(
        location is Map<String, dynamic> ? location : const {},
      ),
      contact: CompanyContact.fromJson(
        contact is Map<String, dynamic> ? contact : const {},
      ),
      requirements: _stringList(json['requisitos']),
      active: json['activa'] is bool ? json['activa'] as bool : false,
      registeredAt: registeredAt is String
          ? DateTime.tryParse(registeredAt)
          : null,
      acceptedAcademicDirections: _stringList(json['direccionesAcademicas']),
      acceptedCareers: _stringList(json['carrerasAceptadas']),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static String? _imageUrl(Object? value) {
    if (value is! Map) return null;
    final url = _string(value['url'])?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}

class CompanyLocation {
  const CompanyLocation({
    this.address,
    this.municipality,
    this.state,
    this.mapUrl,
  });

  final String? address;
  final String? municipality;
  final String? state;
  final String? mapUrl;

  factory CompanyLocation.fromJson(Map<String, dynamic> json) =>
      CompanyLocation(
        address: _string(json['direccion']),
        municipality: _string(json['municipio']),
        state: _string(json['estado']),
        mapUrl: _string(json['mapaUrl']),
      );

  static String? _string(Object? value) => value is String ? value : null;
}

class CompanyContact {
  const CompanyContact({this.email, this.phone});

  final String? email;
  final String? phone;

  factory CompanyContact.fromJson(Map<String, dynamic> json) => CompanyContact(
    email: _string(json['correo']),
    phone: _string(json['telefono']),
  );

  static String? _string(Object? value) => value is String ? value : null;
}

class CompanyListResponse {
  const CompanyListResponse({required this.total, required this.companies});

  final int total;
  final List<CompanyModel> companies;

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) {
    final rawCompanies = json['empresas'];
    final rawTotal = json['total'];
    final total = rawTotal is int ? rawTotal : int.tryParse('$rawTotal');
    if (rawCompanies is! List || total == null) {
      throw const FormatException(
        'La respuesta de empresas no tiene un formato válido.',
      );
    }

    return CompanyListResponse(
      total: total,
      companies: rawCompanies
          .whereType<Map<String, dynamic>>()
          .map(CompanyModel.fromJson)
          .toList(growable: false),
    );
  }
}
