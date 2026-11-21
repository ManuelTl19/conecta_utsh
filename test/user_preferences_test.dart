import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/models/user_preferences_model.dart';
import 'package:conecta_utsh/modules/app/screens/user_preferences_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/services/user_preferences_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('preferences and completion status are isolated by user', () async {
    const service = UserPreferencesService();

    await service.save(
      userId: 'alumno-1',
      preferences: UserPreferencesModel(
        academicLevel: 'Ingeniería',
        employmentTypes: ['Proyecto'],
        modalities: ['En línea'],
      ),
      status: 'omitido',
    );

    expect(await service.hasSeen('alumno-1'), isTrue);
    expect(await service.getStatus('alumno-1'), 'omitido');
    expect(await service.getPreferences('alumno-1'), isNotNull);
    expect(await service.hasSeen('alumno-2'), isFalse);
    expect(await service.getStatus('alumno-2'), isNull);
  });

  testWidgets('saves selected choices and completes the preferences flow', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = const UserPreferencesService();
    final authService = AuthService(tokenStore: _MemoryTokenStore());
    addTearDown(authService.close);
    const user = LoginUserModel(
      id: 'alumno-ti',
      name: 'Ana',
      email: 'ana@example.com',
      role: 'estudiante',
      career: 'Tecnologías de la Información',
      location: 'Hidalgo',
    );

    await tester.pumpWidget(
      Resize(
        builder: () => ui.MaterialApp(
          home: UserPreferencesScreen(
            user: user,
            authService: authService,
            preferencesService: service,
          ),
        ),
      ),
    );

    expect(find.text('Omitir'), findsOneWidget);
    expect(find.text('Atrás'), findsNothing);
    await tester.tap(find.text('Ingeniería'));
    await tester.tap(find.text('Proyecto'));
    await tester.tap(find.text('Backend'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presencial'));
    expect(find.text('Paso 2 de 2'), findsOneWidget);
    expect(find.text('Omitir'), findsNothing);
    expect(find.text('Regresar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.text('Hidalgo'), findsOneWidget);

    await tester.tap(find.text('Regresar'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Híbrido'));
    await tester.tap(find.byType(ui.DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Puebla').last);
    await tester.tap(find.text('Puebla').last);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(await service.getStatus(user.id), 'completado');
    expect(await service.hasSeen(user.id), isTrue);
    final saved = await service.getPreferences(user.id);
    expect(saved?.academicLevel, 'Ingeniería');
    expect(saved?.employmentTypes, ['Proyecto']);
    expect(saved?.specializations, ['Backend']);
    expect(saved?.modalities, ['Presencial', 'Híbrido']);
    expect(saved?.location, 'Puebla');
  });

  testWidgets('omitting saves current selections and marks them omitted', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const service = UserPreferencesService();
    final authService = AuthService(tokenStore: _MemoryTokenStore());
    addTearDown(authService.close);
    const user = LoginUserModel(
      id: 'alumno-no-ti',
      name: 'Luis',
      email: 'luis@example.com',
      role: 'estudiante',
      career: 'Gastronomía',
    );

    await tester.pumpWidget(
      Resize(
        builder: () => ui.MaterialApp(
          home: UserPreferencesScreen(
            user: user,
            authService: authService,
            preferencesService: service,
          ),
        ),
      ),
    );

    expect(find.text('Especialización (opcional)'), findsNothing);
    await tester.tap(find.text('TSU'));
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Luis!'), findsOneWidget);
    expect(await service.getStatus(user.id), 'omitido');
    final saved = await service.getPreferences(user.id);
    expect(saved?.academicLevel, 'TSU');
    expect(saved?.modalities, isEmpty);
    expect(saved?.location, isNull);
  });
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> save(String token) async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> clear() async {}
}
