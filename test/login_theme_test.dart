import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/helpers/constants.dart';
import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/modules/app/screens/login_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await AppSettings.getSettings();
  });

  testWidgets('login theme button toggles and persists dark mode', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Resize(
        builder: () => ui.AnimatedBuilder(
          animation: AppSettings(),
          builder: (context, _) => ui.MaterialApp(
            themeMode: AppSettings.isDarkModeOn
                ? ui.ThemeMode.dark
                : ui.ThemeMode.light,
            home: const LoginScreen(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<ui.MaterialApp>(find.byType(ui.MaterialApp)).themeMode,
      ui.ThemeMode.light,
    );

    await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
    await tester.pumpAndSettle();

    expect(AppSettings.isDarkModeOn, isTrue);
    expect(prefs.getBool(Constants.darkModeKey), isTrue);
    expect(
      tester.widget<ui.MaterialApp>(find.byType(ui.MaterialApp)).themeMode,
      ui.ThemeMode.dark,
    );
    expect(find.byTooltip('Cambiar a modo claro'), findsOneWidget);
  });
}
