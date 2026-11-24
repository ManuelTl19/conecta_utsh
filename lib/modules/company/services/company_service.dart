import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

class CompanyService {
  const CompanyService({this.favoriteUpdater});

  static const String mockUserCareer =
      'Ingeniería en Desarrollo y Gestión de Software';
  static final Set<String> _mockFavoriteIds = {'google'};

  final Future<void> Function(String companyId, bool isFavorite)?
  favoriteUpdater;

  static const List<Map<String, dynamic>> _mockCompanies = [
    {
      '_id': 'shell',
      'nombre': 'Shell México',
      'descripcion': 'Empresa del sector energético con operaciones en México.',
      'sector': 'Energía',
      'areasDisponibles': ['Administración', 'Operaciones', 'Finanzas'],
      'ubicacion': {
        'direccion': 'Blvd. Felipe Ángeles 1200',
        'municipio': 'Pachuca de Soto',
        'estado': 'Hidalgo',
        'mapaUrl': '',
      },
      'contacto': 'vinculacion@shell.example',
      'requisitos': ['CV actualizado'],
      'activa': true,
      'carrerasAceptadas': ['Licenciatura en Administración'],
      'fechaRegistro': '2025-08-20T00:00:00.000Z',
      'calificacionPromedio': 4.2,
      'totalResenas': 8,
      'esFavorita': false,
    },
    {
      '_id': 'spotify',
      'nombre': 'Spotify México',
      'descripcion':
          'Plataforma digital dedicada a servicios de audio y tecnología.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Desarrollo de software', 'Diseño', 'Datos'],
      'ubicacion': {
        'direccion': 'Av. Insurgentes Sur 1602',
        'municipio': 'Benito Juárez',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'talento@spotify.example',
      'requisitos': ['CV actualizado', 'Portafolio'],
      'activa': true,
      'carrerasAceptadas': [
        'Ingeniería en Desarrollo y Gestión de Software',
        'Ingeniería en Tecnologías de la Información e Innovación Digital',
      ],
      'fechaRegistro': '2025-09-10T00:00:00.000Z',
      'calificacionPromedio': 4.8,
      'totalResenas': 12,
      'esFavorita': false,
    },
    {
      '_id': 'pinterest',
      'nombre': 'Pinterest México',
      'descripcion': 'Compañía de tecnología y contenido digital.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Diseño', 'Marketing', 'Desarrollo de software'],
      'ubicacion': {
        'direccion': 'Av. Paseo de la Reforma 250',
        'municipio': 'Miguel Hidalgo',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'contacto@pinterest.example',
      'requisitos': [],
      'activa': true,
      'carrerasAceptadas': ['TSU en Mercadotecnia'],
      'fechaRegistro': '2025-09-18T00:00:00.000Z',
      'calificacionPromedio': 0,
      'totalResenas': 0,
      'esFavorita': false,
    },
    {
      '_id': 'google',
      'nombre': 'Google México',
      'descripcion': 'Empresa de tecnología y servicios digitales.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Diseño UX', 'Desarrollo de software', 'Datos'],
      'ubicacion': {
        'direccion': 'Montes Urales 445',
        'municipio': 'Miguel Hidalgo',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'talento@google.example',
      'requisitos': ['CV actualizado'],
      'activa': true,
      'carrerasAceptadas': [],
      'fechaRegistro': '2025-10-01T00:00:00.000Z',
      'calificacionPromedio': 4.7,
      'totalResenas': 24,
      'esFavorita': true,
    },
    {
      '_id': 'microsoft',
      'nombre': 'Microsoft México',
      'descripcion': 'Empresa de software, nube y servicios tecnológicos.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Desarrollo de software', 'Nube', 'Ciberseguridad'],
      'ubicacion': {
        'direccion': 'Boulevard Manuel Ávila Camacho 137',
        'municipio': 'Naucalpan de Juárez',
        'estado': 'Estado de México',
        'mapaUrl': '',
      },
      'contacto': 'contacto@microsoft.example',
      'requisitos': ['CV actualizado'],
      'activa': true,
      'carrerasAceptadas': [
        'Ingeniería en Desarrollo y Gestión de Software',
        'Ingeniería en Redes Inteligentes y Ciberseguridad',
      ],
      'fechaRegistro': '2025-10-12T00:00:00.000Z',
      'calificacionPromedio': 4.5,
      'totalResenas': 16,
      'esFavorita': false,
    },
    {
      '_id': 'adobe',
      'nombre': 'Adobe México',
      'descripcion': 'Empresa de software creativo y soluciones digitales.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Diseño', 'Desarrollo de software', 'Marketing'],
      'ubicacion': {
        'direccion': 'Av. Santa Fe 440',
        'municipio': 'Cuajimalpa de Morelos',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'contacto@adobe.example',
      'requisitos': ['Portafolio'],
      'activa': true,
      'carrerasAceptadas': ['TSU en Mercadotecnia'],
      'fechaRegistro': '2025-10-15T00:00:00.000Z',
      'calificacionPromedio': 4.1,
      'totalResenas': 5,
      'esFavorita': false,
    },
    {
      '_id': 'amazon',
      'nombre': 'Amazon México',
      'descripcion': 'Empresa de comercio electrónico y servicios en la nube.',
      'sector': 'Comercio y tecnología',
      'areasDisponibles': ['Operaciones', 'Datos', 'Nube'],
      'ubicacion': {
        'direccion': 'Av. de los Insurgentes Sur 1602',
        'municipio': 'Benito Juárez',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'talento@amazon.example',
      'requisitos': ['CV actualizado'],
      'activa': true,
      'carrerasAceptadas': [
        'Ingeniería en Tecnologías de la Información e Innovación Digital',
      ],
      'fechaRegistro': '2025-10-20T00:00:00.000Z',
      'calificacionPromedio': 3.8,
      'totalResenas': 7,
      'esFavorita': false,
    },
    {
      '_id': 'uber',
      'nombre': 'Uber México',
      'descripcion': 'Empresa de tecnología para movilidad y logística.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Operaciones', 'Producto', 'Datos'],
      'ubicacion': {
        'direccion': 'Calle Río Lerma 232',
        'municipio': 'Cuauhtémoc',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'contacto@uber.example',
      'requisitos': [],
      'activa': true,
      'carrerasAceptadas': [],
      'fechaRegistro': '2025-10-25T00:00:00.000Z',
      'calificacionPromedio': 4.4,
      'totalResenas': 10,
      'esFavorita': false,
    },
    {
      '_id': 'airbnb',
      'nombre': 'Airbnb México',
      'descripcion': 'Plataforma digital de hospedaje y experiencias.',
      'sector': 'Turismo y tecnología',
      'areasDisponibles': ['Atención a clientes', 'Marketing', 'Diseño'],
      'ubicacion': {
        'direccion': 'Av. Paseo de la Reforma 296',
        'municipio': 'Cuauhtémoc',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'contacto@airbnb.example',
      'requisitos': [],
      'activa': true,
      'carrerasAceptadas': ['TSU en Mercadotecnia'],
      'fechaRegistro': '2025-11-02T00:00:00.000Z',
      'calificacionPromedio': 0,
      'totalResenas': 0,
      'esFavorita': false,
    },
    {
      '_id': 'canva',
      'nombre': 'Canva México',
      'descripcion': 'Plataforma de diseño y comunicación visual.',
      'sector': 'Tecnología',
      'areasDisponibles': ['Diseño', 'Desarrollo de software', 'Marketing'],
      'ubicacion': {
        'direccion': 'Av. Paseo de la Reforma 296',
        'municipio': 'Cuauhtémoc',
        'estado': 'Ciudad de México',
        'mapaUrl': '',
      },
      'contacto': 'talento@canva.example',
      'requisitos': ['Portafolio'],
      'activa': true,
      'carrerasAceptadas': [
        'Ingeniería en Desarrollo y Gestión de Software',
        'TSU en Desarrollo de Software Multiplataforma',
      ],
      'fechaRegistro': '2025-11-05T00:00:00.000Z',
      'calificacionPromedio': 4.9,
      'totalResenas': 19,
      'esFavorita': false,
    },
  ];

  Future<List<CompanyModel>> getCompanies() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _mockCompanyModels().where((company) => company.active).toList();
  }

  Future<List<CompanyModel>> getFeaturedCompanies() async {
    final companies = await getCompanies();
    final featured =
        companies.where((company) => company.totalReviews > 0).toList()..sort(
          (first, second) =>
              second.averageRating.compareTo(first.averageRating),
        );
    return featured.take(4).toList();
  }

  Future<CompanyFilterOptions> getFilterOptions({
    List<CompanyModel>? sourceCompanies,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final companies = sourceCompanies ?? _mockCompanyModels();
    final municipalities = <String, Set<String>>{};
    for (final company in companies.where((company) => company.active)) {
      if (company.state.isEmpty || company.municipality.isEmpty) continue;
      municipalities
          .putIfAbsent(company.state, () => <String>{})
          .add(company.municipality);
    }

    final sortedStates = municipalities.keys.toList()..sort();
    return CompanyFilterOptions(
      estados: sortedStates,
      municipiosPorEstado: {
        for (final state in sortedStates)
          state: municipalities[state]!.toList()..sort(),
      },
    );
  }

  Future<CompanySearchResult> searchCompanies({
    required String query,
    required CompanyFilters filters,
    int page = 1,
    int limit = 20,
    List<CompanyModel>? sourceCompanies,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final companies = sourceCompanies ?? _mockCompanyModels();
    final normalizedQuery = _normalize(query);
    final careers = filters.carreras.isNotEmpty
        ? filters.carreras.toSet()
        : filters.direccion == null
        ? <String>{}
        : (educationCatalog[filters.direccion] ?? const <String>[]).toSet();

    final results = companies.where((company) {
      if (!company.active) return false;
      if (normalizedQuery.isNotEmpty &&
          !_normalize(
            [company.name, company.sector, ...company.availableAreas].join(' '),
          ).contains(normalizedQuery)) {
        return false;
      }
      if (careers.isNotEmpty &&
          company.acceptedCareers.isNotEmpty &&
          !company.acceptedCareers.any(careers.contains)) {
        return false;
      }
      if (filters.estado != null && company.state != filters.estado) {
        return false;
      }
      if (filters.municipio != null &&
          company.municipality != filters.municipio) {
        return false;
      }
      if (filters.calificacionMin != null &&
          (company.totalReviews == 0 ||
              company.averageRating < filters.calificacionMin!)) {
        return false;
      }
      if (filters.soloFavoritas && !company.isFavorite) return false;
      return true;
    }).toList();

    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 20 : limit.clamp(1, 100).toInt();
    final start = (safePage - 1) * safeLimit;
    final end = (start + safeLimit).clamp(0, results.length).toInt();
    final pageResults = start >= results.length
        ? const <CompanyModel>[]
        : results.sublist(start, end);

    return CompanySearchResult(
      companies: pageResults,
      total: results.length,
      page: safePage,
      limit: safeLimit,
    );
  }

  Future<int> countCompanies({
    required String query,
    required CompanyFilters filters,
    List<CompanyModel>? sourceCompanies,
  }) async {
    final result = await searchCompanies(
      query: query,
      filters: filters,
      page: 1,
      limit: 1,
      sourceCompanies: sourceCompanies,
    );
    return result.total;
  }

  Future<void> updateMockFavorite(String companyId, bool isFavorite) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await favoriteUpdater?.call(companyId, isFavorite);
    setMockFavorite(companyId, isFavorite);
  }

  void setMockFavorite(String companyId, bool isFavorite) {
    if (isFavorite) {
      _mockFavoriteIds.add(companyId);
    } else {
      _mockFavoriteIds.remove(companyId);
    }
  }

  List<CompanyModel> _mockCompanyModels() => _mockCompanies
      .map(CompanyModel.fromJson)
      .map(
        (company) =>
            company.copyWith(isFavorite: _mockFavoriteIds.contains(company.id)),
      )
      .toList();

  String _normalize(String value) {
    final normalized = value.toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    return accents.entries.fold(
      normalized,
      (result, accent) => result.replaceAll(accent.key, accent.value),
    );
  }
}

class CompanySearchResult {
  const CompanySearchResult({
    required this.companies,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<CompanyModel> companies;
  final int total;
  final int page;
  final int limit;
}
