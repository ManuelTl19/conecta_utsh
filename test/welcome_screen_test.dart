import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as ui;
import 'package:resize/resize.dart';

import 'package:conecta_utsh/modules/app/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome screen builds with resize initialized', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const ui.Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Resize(builder: () => const ui.MaterialApp(home: WelcomeScreen())),
    );

    expect(find.text('Vincula UTSH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
