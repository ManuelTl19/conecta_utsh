class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sector,
    required this.availableAreas,
    required this.address,
    required this.municipality,
    required this.state,
    required this.mapUrl,
    required this.contact,
    required this.requirements,
    required this.active,
    required this.acceptedCareers,
    required this.registeredAt,
    required this.averageRating,
    required this.totalReviews,
    required this.isFavorite,
  });

  final String id;
  final String name;
  final String description;
  final String sector;
  final List<String> availableAreas;
  final String address;
  final String municipality;
  final String state;
  final String mapUrl;
  final String contact;
  final List<String> requirements;
  final bool active;
  final List<String> acceptedCareers;
  final String registeredAt;
  final double averageRating;
  final int totalReviews;
  final bool isFavorite;

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final location = json['ubicacion'];
    final areas = json['areasDisponibles'] ?? const [];
    final requirements = json['requisitos'] ?? const [];
    final careers = json['carrerasAceptadas'] ?? const [];
    final rating = json['calificacionPromedio'] ?? 0;
    final reviewCount = json['totalResenas'] ?? 0;
    final registeredAt = json['fechaRegistro'] ?? '';
    final description = json['descripcion'] ?? '';
    final contact = json['contacto'] ?? '';
    final active = json['activa'] ?? true;
    final isFavorite = json['esFavorita'];

    if (id is! String ||
        json['nombre'] is! String ||
        description is! String ||
        json['sector'] is! String ||
        areas is! List ||
        areas.any((area) => area is! String) ||
        location is! Map<String, dynamic> ||
        location['municipio'] is! String ||
        location['estado'] is! String ||
        (location['direccion'] != null && location['direccion'] is! String) ||
        (location['mapaUrl'] != null && location['mapaUrl'] is! String) ||
        contact is! String ||
        requirements is! List ||
        requirements.any((item) => item is! String) ||
        active is! bool ||
        careers is! List ||
        careers.any((career) => career is! String) ||
        registeredAt is! String ||
        rating is! num ||
        reviewCount is! int ||
        (isFavorite != null && isFavorite is! bool)) {
      throw const FormatException('Los datos de la empresa no son válidos.');
    }

    return CompanyModel(
      id: id,
      name: json['nombre'] as String,
      description: description,
      sector: json['sector'] as String,
      availableAreas: List<String>.from(areas),
      address: location['direccion'] as String? ?? '',
      municipality: location['municipio'] as String,
      state: location['estado'] as String,
      mapUrl: location['mapaUrl'] as String? ?? '',
      contact: contact,
      requirements: List<String>.from(requirements),
      active: active,
      acceptedCareers: List<String>.from(careers),
      registeredAt: registeredAt,
      averageRating: rating.toDouble(),
      totalReviews: reviewCount,
      isFavorite: isFavorite as bool? ?? false,
    );
  }

  CompanyModel copyWith({bool? isFavorite}) => CompanyModel(
    id: id,
    name: name,
    description: description,
    sector: sector,
    availableAreas: availableAreas,
    address: address,
    municipality: municipality,
    state: state,
    mapUrl: mapUrl,
    contact: contact,
    requirements: requirements,
    active: active,
    acceptedCareers: acceptedCareers,
    registeredAt: registeredAt,
    averageRating: averageRating,
    totalReviews: totalReviews,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}
