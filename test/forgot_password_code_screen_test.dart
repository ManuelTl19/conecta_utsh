import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/modules/app/screens/forgot_password_code_screen.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/password_reset_state_store.dart';

void main() {
  testWidgets('code confirmation unlocks password fields on the same screen', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final stateStore = PasswordResetStateStore();
    final state = PasswordResetState(
      email: 'juan@example.com',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
    await stateStore.save(state);
    final authService = AuthService();
    addTearDown(authService.close);

    await tester.pumpWidget(
      Resize(
        builder: () => ui.MaterialApp(
          home: ForgotPasswordCodeScreen(
            authService: authService,
            state: state,
            stateStore: stateStore,
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const ui.SizedBox.shrink());
    });

    expect(find.byType(ui.BackButton), findsNothing);
    expect(find.byType(ui.TextField), findsNWidgets(6));
    expect(find.text('¿Correo incorrecto? Usar otro correo'), findsOneWidget);

    final codeFields = find.byType(ui.TextField);
    final firstCellSize = tester.getSize(codeFields.first);
    for (var index = 1; index < 6; index++) {
      expect(tester.getSize(codeFields.at(index)), firstCellSize);
    }
    for (var index = 0; index < 6; index++) {
      await tester.enterText(codeFields.at(index), '${index + 1}');
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar código'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva contraseña'), findsWidgets);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
    expect(find.byType(ui.TextField), findsNWidgets(8));
    expect(find.byType(ui.TextFormField), findsNWidgets(2));
    expect(find.byTooltip('Requisitos de contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Requisitos de contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Aceptar'), findsOneWidget);
    expect(
      find.text(
        '• Mínimo 8 caracteres\n• Al menos una mayúscula\n'
        '• Al menos un número\n• Al menos un carácter especial',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const ui.SizedBox.shrink());
  });
}
