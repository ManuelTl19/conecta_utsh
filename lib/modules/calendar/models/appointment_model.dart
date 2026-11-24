class AppointmentModel {
  final String? id;
  final String title;
  final String direccion;
  final String date;       // Fecha seleccionada (ej. "2026-11-18" o "18 nov")
  final String time;       // Horario elegido (ej. "10:00")
  final String? range;     // Rango (ej. "10:00–10:30 h")
  final String? motivo;
  final String status;     // "Pendiente", "Confirmada", "Cancelada"

  AppointmentModel({
    this.id,
    this.title = 'Atención de Estadías',
    required this.direccion,
    required this.date,
    required this.time,
    this.range,
    this.motivo,
    this.status = 'Confirmada',
  });

  // Para leer tus citas desde el Backend (GET /api/citas/mis-citas)
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id']?.toString(),
      title: json['title'] ?? 'Atención de Estadías',
      direccion: json['direccion'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      range: json['range'],
      motivo: json['motivo'],
      status: json['status'] ?? 'Pendiente',
    );
  }

  // Para enviar la cita al Backend al dar clic en "Confirmar cita" (POST /api/citas)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'direccion': direccion,
      'date': date,
      'time': time,
      if (range != null) 'range': range,
      if (motivo != null && motivo!.isNotEmpty) 'motivo': motivo,
    };
  }
}
