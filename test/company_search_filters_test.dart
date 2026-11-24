import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_utsh/modules/company/components/company_search_filters.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';

void main() {
  const companies = [
    CompanyModel(
      id: 'featured-saved',
      name: 'Empresa Norte',
      description: '',
      sector: 'Tecnología',
      availableAreas: ['Desarrollo de software', 'Flutter'],
      address: '',
      municipality: 'Pachuca',
      state: 'Hidalgo',
      mapUrl: '',
      contact: '',
      requirements: [],
      active: true,
      acceptedCareers: [],
      registeredAt: '',
      averageRating: 4.5,
      totalReviews: 2,
      isFavorite: true,
    ),
    CompanyModel(
      id: 'regular',
      name: 'Empresa Sur',
      description: '',
      sector: 'Diseño',
      availableAreas: ['Diseño gráfico'],
      address: '',
      municipality: 'Tulancingo',
      state: 'Hidalgo',
      mapUrl: '',
      contact: '',
      requirements: [],
      active: true,
      acceptedCareers: ['TSU en Mercadotecnia'],
      registeredAt: '',
      averageRating: 0,
      totalReviews: 0,
      isFavorite: false,
    ),
  ];

  test('company filters combine sector and area search', () {
    final results = filterCompanies(
      companies,
      searchQuery: 'FLUTTER',
      selectedFilter: 'Tecnología',
    );

    expect(results.map((company) => company.id), ['featured-saved']);
  });

  test('company filter options include sectors and favorites', () {
    expect(companyFilterOptions(companies), [
      'Todas',
      'Favoritas',
      'Diseño',
      'Tecnología',
    ]);
  });

  test('search finds a sector even if the sector filter is not selected', () {
    final results = filterCompanies(
      companies,
      searchQuery: 'diseño',
      selectedFilter: 'Todas',
    );

    expect(results.map((company) => company.id), ['regular']);
  });
}
