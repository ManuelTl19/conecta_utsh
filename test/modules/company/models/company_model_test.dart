import 'package:conecta_utsh/modules/company/models/company_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompanyModel image URL', () {
    test('reads the URL from the populated image object', () {
      final company = CompanyModel.fromJson({
        'imagen': {
          'url': 'https://cdn.example.com/company.jpg',
          'key': 'companies/company.jpg',
          'contentType': 'image/jpeg',
        },
      });

      expect(company.imageUrl, 'https://cdn.example.com/company.jpg');
    });

    test('leaves the URL empty when the company has no usable image', () {
      final withoutImage = CompanyModel.fromJson({});
      final emptyImage = CompanyModel.fromJson({
        'imagen': {'url': '   '},
      });

      expect(withoutImage.imageUrl, isNull);
      expect(emptyImage.imageUrl, isNull);
    });
  });
}
