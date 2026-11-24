import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:conecta_utsh/modules/company/screens/company_details_screen.dart';

void main() {
  testWidgets('company details shows sample reviews without an about tab', (
    tester,
  ) async {
    const company = CompanyModel(
      id: 'test-company',
      name: 'Empresa de prueba',
      description: 'Empresa de prueba del sector tecnológico.',
      sector: 'Tecnología',
      availableAreas: ['Desarrollo de software'],
      address: '',
      municipality: 'Pachuca de Soto',
      state: 'Hidalgo',
      mapUrl: '',
      contact: '',
      requirements: ['CV actualizado'],
      active: true,
      acceptedCareers: [],
      registeredAt: '',
      averageRating: 4.7,
      totalReviews: 3,
      isFavorite: false,
    );

    await tester.pumpWidget(
      const MaterialApp(home: CompanyDetailScreen(company: company)),
    );

    expect(find.text('Acerca de'), findsNothing);
    await tester.tap(find.text('Reseñas'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Martínez'), findsOneWidget);
    expect(find.text('Carlos Hernández'), findsOneWidget);
    expect(find.text('Sofía Ramírez'), findsOneWidget);
    expect(find.text('3 reseñas'), findsOneWidget);
  });
}
