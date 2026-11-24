import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

void main() {
  const service = CompanyService();

  test(
    'direction expands to its careers and companies accepting all remain',
    () async {
      final careers = educationCatalog['Tecnologías de la Información']!
          .toSet();
      final result = await service.searchCompanies(
        query: '',
        filters: const CompanyFilters(
          direccion: 'Tecnologías de la Información',
        ),
      );

      expect(result.companies.map((company) => company.id), contains('google'));
      expect(
        result.companies.every(
          (company) =>
              company.acceptedCareers.isEmpty ||
              company.acceptedCareers.any(careers.contains),
        ),
        isTrue,
      );
    },
  );

  test('rating threshold excludes companies without visible reviews', () async {
    final result = await service.searchCompanies(
      query: '',
      filters: const CompanyFilters(calificacionMin: 4.5),
    );

    expect(result.companies, isNotEmpty);
    expect(
      result.companies.every((company) => company.totalReviews > 0),
      isTrue,
    );
    expect(
      result.companies.every((company) => company.averageRating >= 4.5),
      isTrue,
    );
  });

  test('state, municipality, and favorite filters combine', () async {
    final result = await service.searchCompanies(
      query: '',
      filters: const CompanyFilters(
        estado: 'Ciudad de México',
        municipio: 'Miguel Hidalgo',
        soloFavoritas: true,
      ),
    );

    expect(result.total, 1);
    expect(result.companies.single.id, 'google');
  });

  test(
    'filter options only include mock states and municipalities in use',
    () async {
      final options = await service.getFilterOptions();

      expect(options.estados, contains('Hidalgo'));
      expect(options.municipiosDe('Hidalgo'), contains('Pachuca de Soto'));
      expect(options.municipiosDe('Estado sin empresas'), isEmpty);
    },
  );
}
