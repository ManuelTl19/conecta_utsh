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
    final rawTime =
        json['time'] ?? json['hora'] ?? json['horario'] ?? json['horaInicio'];
    final time = _normalizeTime(rawTime?.toString() ?? '');
    final rawAvailability =
        json['available'] ?? json['isAvailable'] ?? json['disponible'];
    final status = (json['estado'] ?? json['status'] ?? '')
        .toString()
        .toLowerCase();
    final isAvailable = switch (rawAvailability) {
      bool value => value,
      num value => value != 0,
      String value => switch (value.toLowerCase()) {
        'true' || '1' || 'disponible' || 'available' || 'libre' => true,
        'false' || '0' || 'ocupado' || 'reservado' || 'no disponible' => false,
        _ => _isAvailableStatus(status),
      },
      _ => _isAvailableStatus(status),
    };

    return TimeSlotModel(
      time: time,
      range:
          (json['range'] ?? json['rango'])?.toString() ??
          (time.isEmpty ? '' : '$time–${_addMinutes(time, 10)} h'),
      isAvailable: isAvailable,
    );
  }

  static bool _isAvailableStatus(String status) =>
      !{'ocupado', 'reservado', 'no disponible', 'unavailable'}
          .contains(status);

  static String _normalizeTime(String value) {
    if (value.contains('T')) {
      final date = DateTime.tryParse(value)?.toLocal();
      if (date != null) return _formatTime(date);
    }
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  static String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final totalMinutes =
        (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0) +
        minutes;
    return '${(totalMinutes ~/ 60).toString().padLeft(2, '0')}:${(totalMinutes % 60).toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
    final rawDate = (json['rawDate'] ?? json['fecha'] ?? json['date'] ?? '')
        .toString();
    final slotsJson = _readSlots(json);
    final date = DateTime.tryParse(rawDate);
    return AvailableDateModel(
      rawDate: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      labelDate: (json['labelDate'] ?? (date == null ? '' : _formatDate(date)))
          .toString(),
      dayName: (json['dayName'] ?? (date == null ? '' : _dayName(date)))
          .toString(),
      slots: slotsJson.map(_slotFromJson).toList(),
    );
  }

  static List<dynamic> _readSlots(Map<String, dynamic> json) {
    final slots = json['slots'] ?? json['horarios'] ?? json['horariosDisponibles'];
    final available = slots is List ? slots : const <dynamic>[];
    final occupied = json['horariosOcupados'];
    if (occupied is! List) return available;
    return [
      ...available,
      ...occupied.map((slot) => _markUnavailable(slot)),
    ];
  }

  static dynamic _markUnavailable(dynamic slot) {
    if (slot is String) return {'hora': slot, 'disponible': false};
    if (slot is Map) {
      return {...Map<String, dynamic>.from(slot), 'disponible': false};
    }
    return slot;
  }

  static TimeSlotModel _slotFromJson(dynamic value) {
    if (value is String) {
      return TimeSlotModel.fromJson({'hora': value, 'disponible': true});
    }
    if (value is Map<String, dynamic>) {
      return TimeSlotModel.fromJson(value);
    }
    if (value is Map) {
      return TimeSlotModel.fromJson(Map<String, dynamic>.from(value));
    }
    throw const FormatException('El horario devuelto no es válido.');
  }

  static String _formatDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  static String _dayName(DateTime date) => _days[date.weekday - 1];

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

  static const _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
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