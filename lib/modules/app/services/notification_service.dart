import 'package:conecta_utsh/modules/app/models/app_notification_model.dart';

class NotificationService {
  const NotificationService();

  static const _mockNotifications = [
    {
      'id': 'new-jobs',
      'title': 'Nuevas vacantes para ti',
      'message': 'Hay oportunidades que coinciden con tus preferencias.',
      'dateLabel': 'Hace 2 horas',
      'isRead': false,
    },
    {
      'id': 'profile-tip',
      'title': 'Completa tu perfil',
      'message': 'Agrega más información para mejorar tus recomendaciones.',
      'dateLabel': 'Ayer',
      'isRead': false,
    },
  ];

  Future<List<AppNotificationModel>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _mockNotifications.map(AppNotificationModel.fromJson).toList();
  }
}
