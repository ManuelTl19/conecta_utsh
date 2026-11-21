import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_utsh/modules/app/models/education_catalog.dart';

void main() {
  test('cuatrimestres depend on the selected career level', () {
    expect(
      cuatrimestresForCareer('TSU en Desarrollo de Software Multiplataforma'),
      [1, 2, 3, 4, 5, 6],
    );
    expect(
      cuatrimestresForCareer('Ingeniería en Desarrollo y Gestión de Software'),
      [7, 8, 9, 10],
    );
    expect(cuatrimestresForCareer('Licenciatura en Administración'), [
      7,
      8,
      9,
      10,
    ]);
    expect(cuatrimestresForCareer(null), isEmpty);
  });
}
