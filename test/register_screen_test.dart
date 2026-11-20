import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';

import 'package:conecta_utsh/modules/app/screens/login_screen.dart';

void main() {
  testWidgets('registration advances through two validated steps', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Resize(builder: () => const ui.MaterialApp(home: LoginScreen())),
    );
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('1. Datos personales'), findsOneWidget);
    expect(find.text('2. Acceso'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsNothing);

    final personalValues = ['Ana', 'López', 'Pérez', '12345678', 'Ingeniería'];
    for (var index = 0; index < personalValues.length; index++) {
      final field = find.byType(ui.TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, personalValues[index]);
    }

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Matrícula'), findsOneWidget);
  });
}
