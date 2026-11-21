class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.dateLabel,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String dateLabel;
  final bool isRead;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['title'] is! String ||
        json['message'] is! String ||
        json['dateLabel'] is! String ||
        json['isRead'] is! bool) {
      throw const FormatException('Los datos de notificación no son válidos.');
    }

    return AppNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      dateLabel: json['dateLabel'] as String,
      isRead: json['isRead'] as bool,
    );
  }
}
