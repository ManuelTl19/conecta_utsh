import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';

import 'package:conecta_utsh/modules/app/models/login_response_model.dart';
import 'package:conecta_utsh/modules/app/screens/home_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';

void main() {
  testWidgets('home shows the signed-in user and clears token on logout', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tokenStore = _MemoryTokenStore()..token = 'test-token';
    final authService = AuthService(
      loginEndpoint: Uri.parse('http://localhost/login'),
      registerEndpoint: Uri.parse('http://localhost/register'),
      tokenStore: tokenStore,
    );
    addTearDown(authService.close);

    await tester.pumpWidget(
      Resize(
        builder: () => ui.MaterialApp(
          home: widgets.Builder(
            builder: (context) => ui.TextButton(
              onPressed: () => widgets.Navigator.of(context).push(
                ui.MaterialPageRoute<void>(
                  builder: (_) => HomeScreen(
                    user: const LoginUserModel(
                      id: 'user-id',
                      name: 'Juan',
                      email: 'juan@example.com',
                      role: 'estudiante',
                    ),
                    authService: authService,
                  ),
                ),
              ),
              child: const ui.Text('Abrir inicio'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir inicio'));
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Juan!'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(tokenStore.token, isNull);
    expect(find.text('Abrir inicio'), findsOneWidget);
  });
}

class _MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> save(String token) async {
    this.token = token;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async {
    token = null;
  }
}
