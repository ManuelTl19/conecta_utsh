class AppointmentModel {
  final String? id;
  final String title;
  final String direccion;
  final String date;       // Fecha seleccionada (ej. "2026-11-18" o "18 nov")
  final String time;       // Horario elegido (ej. "10:00")
  final String? range;     // Rango (ej. "10:00–10:30 h")
  final String? motivo;
  final String status;     // "Pendiente", "Confirmada", "Cancelada"
  final DateTime? fechaHora;
  final int? duracionMinutos;

  AppointmentModel({
    this.id,
    this.title = 'Atención de Estadías',
    required this.direccion,
    required this.date,
    required this.time,
    this.range,
    this.motivo,
    this.status = 'Confirmada',
    this.fechaHora,
    this.duracionMinutos,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final rawFechaHora = json['fechaHora'] ?? json['dateTime'];
    final fechaHora = rawFechaHora == null
        ? null
        : DateTime.parse(rawFechaHora.toString()).toLocal();
    final duracion = json['duracionMinutos'];
    final rawStatus = (json['estado'] ?? json['status'] ?? 'pendiente')
        .toString()
        .toLowerCase();
    final status = switch (rawStatus) {
      'confirmada' => 'Confirmada',
      'cancelada' => 'Cancelada',
      'completada' => 'Completada',
      _ => 'Pendiente',
    };

    return AppointmentModel(
      id: json['_id']?.toString(),
      title: json['title'] ?? 'Atención de Estadías',
      direccion: json['direccion'] ?? 'Área de Estadías',
      date: fechaHora == null ? json['date'] ?? '' : _formatDate(fechaHora),
      time: fechaHora == null ? json['time'] ?? '' : _formatTime(fechaHora),
      range:
          json['range'] ??
          (fechaHora != null && duracion is num
              ? '${_formatTime(fechaHora)}–${_formatTime(fechaHora.add(Duration(minutes: duracion.toInt())))} h'
              : null),
      motivo: json['motivo']?.toString(),
      status: status,
      fechaHora: fechaHora,
      duracionMinutos: duracion is num ? duracion.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fechaHora != null) 'fechaHora': fechaHora!.toUtc().toIso8601String(),
      if (duracionMinutos != null) 'duracionMinutos': duracionMinutos,
      if (motivo != null) 'motivo': motivo,
    };
  }

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
