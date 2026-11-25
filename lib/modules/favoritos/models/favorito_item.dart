import 'package:conecta_utsh/modules/company/models/company_model.dart';

class FavoritoItem {
  const FavoritoItem({
    required this.idRegistro,
    required this.empresa,
    required this.fechaRegistro,
  });

  final String idRegistro;
  final CompanyModel empresa;
  final DateTime fechaRegistro;

  factory FavoritoItem.fromJson(Map<String, dynamic> json) {
    final rawCompany = json['empresa'];
    final rawDate = json['fechaRegistro'];
    final id = json['_id'] ?? json['idRegistro'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;

    if (rawCompany is! Map<String, dynamic> ||
        id == null ||
        date == null) {
      throw const FormatException(
        'Un registro de favoritos no tiene un formato válido.',
      );
    }

    return FavoritoItem(
      idRegistro: id.toString(),
      empresa: CompanyModel.fromJson(rawCompany),
      fechaRegistro: date,
    );
  }
}
