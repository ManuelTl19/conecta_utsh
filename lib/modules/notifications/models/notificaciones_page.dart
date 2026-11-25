import 'package:conecta_utsh/modules/notifications/models/notificacion.dart';

class NotificacionesPage {
  const NotificacionesPage({
    required this.total,
    required this.totalNoLeidas,
    required this.pagina,
    required this.limite,
    required this.totalPaginas,
    required this.notificaciones,
  });

  final int total;
  final int totalNoLeidas;
  final int pagina;
  final int limite;
  final int totalPaginas;
  final List<Notificacion> notificaciones;

  factory NotificacionesPage.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json['notificaciones'];
    if (rawNotifications is! List) {
      throw const FormatException(
        'La respuesta de notificaciones no es válida.',
      );
    }

    return NotificacionesPage(
      total: _readInt(json['total']),
      totalNoLeidas: _readInt(json['totalNoLeidas']),
      pagina: _readInt(json['pagina']),
      limite: _readInt(json['limite']),
      totalPaginas: _readInt(json['totalPaginas']),
      notificaciones: rawNotifications
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'La respuesta contiene una notificación no válida.',
              );
            }
            return Notificacion.fromJson(item);
          })
          .toList(growable: false),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw const FormatException(
        'La respuesta de notificaciones no es válida.',
      );
    }
    return parsed;
  }
}
