import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/screens/company_screen.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

void main() {
  const company = CompanyModel(
    id: 'test-company',
    name: 'Empresa de prueba',
    description: 'Descripción',
    sector: 'Tecnología',
    availableAreas: ['Software', 'Software', 'Diseño', 'Datos', 'Operaciones'],
    address: '',
    municipality: 'Pachuca de Soto',
    state: 'Hidalgo',
    mapUrl: '',
    contact: '',
    requirements: [],
    active: true,
    acceptedCareers: [],
    registeredAt: '',
    averageRating: 0,
    totalReviews: 0,
    isFavorite: false,
  );

  testWidgets('catalog card uses company data and deduplicated areas', (
    tester,
  ) async {
    await tester.pumpWidget(
      Resize(
        builder: () => const MaterialApp(
          home: CompaniesScreen(initialCompanies: [company]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa de prueba'), findsOneWidget);
    expect(find.text('Tecnología · Pachuca de Soto, Hidalgo'), findsOneWidget);
    expect(find.text('Sin reseñas aún'), findsOneWidget);
    expect(find.text('Acepta todas las carreras'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.textContaining('Junior'), findsNothing);
    expect(find.textContaining('Tiempo completo'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('favorite is optimistic and reverts when mock update fails', (
    tester,
  ) async {
    final service = CompanyService(
      favoriteUpdater: (_, _) async => throw Exception('mock failure'),
    );
    await tester.pumpWidget(
      Resize(
        builder: () => MaterialApp(
          home: CompaniesScreen(
            initialCompanies: [company],
            companyService: service,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Agregar a favoritas'));
    await tester.pump();
    expect(find.byTooltip('Quitar de favoritas'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Agregar a favoritas'), findsOneWidget);
    expect(
      find.text('No se pudo actualizar la empresa favorita.'),
      findsOneWidget,
    );
  });

  test('catalog response can omit detail-only fields', () {
    final parsed = CompanyModel.fromJson({
      '_id': 'api-company',
      'nombre': 'Empresa API',
      'sector': 'Tecnología',
      'areasDisponibles': ['Desarrollo'],
      'ubicacion': {'municipio': 'Pachuca', 'estado': 'Hidalgo'},
      'carrerasAceptadas': [],
      'calificacionPromedio': 4.25,
      'totalResenas': 2,
      'esFavorita': true,
    });

    expect(parsed.id, 'api-company');
    expect(parsed.averageRating, 4.25);
    expect(parsed.totalReviews, 2);
    expect(parsed.isFavorite, isTrue);
    expect(parsed.description, isEmpty);
    expect(parsed.requirements, isEmpty);
  });
}
