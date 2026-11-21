import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';

import 'package:conecta_utsh/modules/app/screens/login_screen.dart';

void main() {
  Future<void> dismissAlert(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
  }

  Future<void> selectEducationData(WidgetTester tester) async {
    expect(find.byType(ui.DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(ui.DropdownButtonFormField<int>), findsNothing);

    final direction = find.byType(ui.DropdownButtonFormField<String>).at(0);
    await tester.ensureVisible(direction);
    await tester.tap(direction);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tecnologías de la Información').last);
    await tester.pumpAndSettle();
    expect(find.byType(ui.DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.byType(ui.DropdownButtonFormField<int>), findsNothing);

    final career = find.byType(ui.DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(career);
    await tester.tap(career);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingeniería en Desarrollo y Gestión de Software'));
    await tester.pumpAndSettle();
    expect(find.byType(ui.DropdownButtonFormField<int>), findsOneWidget);

    final semester = find.byType(ui.DropdownButtonFormField<int>);
    await tester.ensureVisible(semester);
    await tester.tap(semester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7° cuatrimestre'));
    await tester.pumpAndSettle();
  }

  Future<void> openRegistration(WidgetTester tester) async {
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
  }

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

    expect(find.text('Datos personales'), findsOneWidget);
    expect(find.text('Acceso'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsNothing);

    final personalValues = [
      'Ana',
      'López',
      'Pérez',
      '12345678',
    ];
    for (var index = 0; index < personalValues.length; index++) {
      final field = find.byType(ui.TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, personalValues[index]);
    }

    await selectEducationData(tester);
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Matrícula'), findsOneWidget);
  });

  testWidgets('registration filters invalid input and validates lengths', (
    tester,
  ) async {
    await openRegistration(tester);

    final firstName = find.byType(ui.TextFormField).at(0);
    await tester.enterText(firstName, 'A B');
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe al menos 3 letras'), findsOneWidget);
    expect(find.text('Faltan datos'), findsOneWidget);
    await dismissAlert(tester);

    final personalValues = [
      'A1na',
      'López 123',
      'Pérez',
      '1234abcd',
    ];
    for (var index = 0; index < personalValues.length; index++) {
      final field = find.byType(ui.TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, personalValues[index]);
    }

    expect(
      tester
          .widget<ui.TextFormField>(find.byType(ui.TextFormField).at(0))
          .controller!
          .text,
      'Ana',
    );
    expect(
      tester
          .widget<ui.TextFormField>(find.byType(ui.TextFormField).at(3))
          .controller!
          .text,
      '1234',
    );

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text('La matrícula debe tener exactamente 8 dígitos'),
      findsOneWidget,
    );
    await dismissAlert(tester);

    final enrollment = find.byType(ui.TextFormField).at(3);
    await tester.ensureVisible(enrollment);
    await tester.enterText(enrollment, '20260001');
    await selectEducationData(tester);
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    final accountValues = ['alumno@utsh', '771123456', '       ', 'otraClave'];
    for (var index = 0; index < accountValues.length; index++) {
      final field = find.byType(ui.TextFormField).at(index);
      await tester.ensureVisible(field);
      await tester.enterText(field, accountValues[index]);
    }
    var submitButton = find.text('Registrarse').last;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    await dismissAlert(tester);

    final email = find.byType(ui.TextFormField).at(0);
    await tester.ensureVisible(email);
    await tester.enterText(email, 'alumno@utsh.edu.mx');
    submitButton = find.text('Registrarse').last;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un teléfono de 10 dígitos'), findsOneWidget);
    await dismissAlert(tester);

    final phone = find.byType(ui.TextFormField).at(1);
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '7711234567');
    submitButton = find.text('Registrarse').last;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    await dismissAlert(tester);

    final password = find.byType(ui.TextFormField).at(2);
    await tester.ensureVisible(password);
    await tester.enterText(password, '1234567');
    final confirmation = find.byType(ui.TextFormField).at(3);
    await tester.ensureVisible(confirmation);
    await tester.enterText(confirmation, '1234567');
    submitButton = find.text('Registrarse').last;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);
    await dismissAlert(tester);

    await tester.ensureVisible(password);
    await tester.enterText(password, 'Password1');
    await tester.ensureVisible(confirmation);
    await tester.enterText(confirmation, 'Password2');
    submitButton = find.text('Registrarse').last;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    await dismissAlert(tester);
  });
}
