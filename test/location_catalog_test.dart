import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_utsh/modules/app/models/location_catalog.dart';

void main() {
  test('location choices contain all states and the international option', () {
    expect(mexicanLocations.length, mexicanStateCount + 1);
    expect(mexicanLocations.toSet().length, mexicanLocations.length);
    expect(mexicanLocations.last, 'Fuera de México');
  });
}
