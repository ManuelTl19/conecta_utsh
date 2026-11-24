import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:resize/resize.dart';
import 'package:conecta_utsh/modules/app/models/education_catalog.dart';
import 'package:conecta_utsh/modules/company/components/company_filters_sheet.dart';
import 'package:conecta_utsh/modules/company/models/company_filters.dart';
import 'package:conecta_utsh/modules/company/services/company_service.dart';

void main() {
  testWidgets(
    'direction picker restricts multi-select careers to registration options',
    (tester) async {
      const service = CompanyService();
      await tester.pumpWidget(
        Resize(
          builder: () => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CompanyFiltersSheet(
                      initialFilters: CompanyFilters(),
                      query: '',
                      companyService: service,
                    ),
                  ),
                  child: const Text('Abrir filtros'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir filtros'));
      await tester.pumpAndSettle();

      const direction = 'Tecnologías de la Información';
      await tester.tap(find.byKey(const ValueKey('direccion-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(direction).last);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('carreras-picker')));
      await tester.pumpAndSettle();
      final careers = educationCatalog[direction]!;
      expect(
        find.byKey(ValueKey('career-options-${careers.length}')),
        findsOneWidget,
      );
      expect(find.text(careers[0]), findsOneWidget);
      expect(find.text('Licenciatura en Terapia Física'), findsNothing);

      await tester.tap(find.text(careers[0]));
      await tester.pump();
      await tester.tap(find.text(careers[1]));
      await tester.pump();
      expect(find.text('Listo (2)'), findsOneWidget);
      await tester.tap(find.text('Listo (2)'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('2 carreras seleccionadas'), findsOneWidget);
    },
  );
}
