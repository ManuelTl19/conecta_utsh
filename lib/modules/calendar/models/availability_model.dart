class TimeSlotModel {
  final String time;       // Ej: "09:00"
  final String range;      // Ej: "09:00–09:30 h"
  final bool isAvailable;  // true = Libre, false = Ocupado

  TimeSlotModel({
    required this.time,
    required this.range,
    required this.isAvailable,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      time: json['time'] ?? '',
      range: json['range'] ?? '',
      isAvailable: json['available'] ?? json['isAvailable'] ?? false,
    );
  }
}

class AvailableDateModel {
  final String rawDate;    // Ej: "2026-11-18" (para enviarlo al backend)
  final String labelDate;  // Ej: "18 nov" (para mostrar en la tarjeta)
  final String dayName;    // Ej: "Miércoles"
  final List<TimeSlotModel> slots;

  AvailableDateModel({
    required this.rawDate,
    required this.labelDate,
    required this.dayName,
    required this.slots,
  });

  factory AvailableDateModel.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List? ?? [];
    return AvailableDateModel(
      rawDate: json['rawDate'] ?? '',
      labelDate: json['labelDate'] ?? '',
      dayName: json['dayName'] ?? '',
      slots: slotsJson.map((s) => TimeSlotModel.fromJson(s)).toList(),
    );
  }
}

class DirectionAvailabilityModel {
  final String direccion;
  final bool hasAttention;          // false si no hay atención para esa dirección
  final String attentionSchedule;   // Ej: "Atención: miércoles · 09:00 a 12:00 h"
  final String? noAttentionMessage; // Ej: "Por el momento no hay fechas disponibles"
  final List<AvailableDateModel> availableDates;

  DirectionAvailabilityModel({
    required this.direccion,
    required this.hasAttention,
    required this.attentionSchedule,
    this.noAttentionMessage,
    required this.availableDates,
  });

  factory DirectionAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final datesJson = json['availableDates'] as List? ?? [];
    return DirectionAvailabilityModel(
      direccion: json['direccion'] ?? '',
      hasAttention: json['hasAttention'] ?? true,
      attentionSchedule: json['attentionSchedule'] ?? '',
      noAttentionMessage: json['noAttentionMessage'],
      availableDates:
          datesJson.map((d) => AvailableDateModel.fromJson(d)).toList(),
    );
  }
}