import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/helpers/providers/app_settings.dart';
import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/modules/app/components/quick_menu.dart';
import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/screens/dashboard_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await AppSettings.getSettings();
  });

  testWidgets('dashboard keeps navigation shell while swiping tabs', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authService = AuthService(tokenStore: _MemoryTokenStore());
    addTearDown(authService.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(
          user: const LoginUserModel(
            id: 'user-id',
            name: 'Ana',
            email: 'ana@example.com',
            role: 'estudiante',
          ),
          authService: authService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido de nuevo!'), findsOneWidget);
    expect(find.byType(QuickMenu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Configuraciones'), findsOneWidget);
    expect(find.byType(QuickMenu), findsOneWidget);

    await tester.drag(find.byType(PageView).first, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('¡Bienvenido de nuevo!'), findsOneWidget);
    expect(find.byType(QuickMenu), findsOneWidget);
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
