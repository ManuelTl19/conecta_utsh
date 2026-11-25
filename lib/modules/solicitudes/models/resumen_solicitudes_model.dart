class ResumenSolicitudesModel {
  const ResumenSolicitudesModel({
    required this.limiteSolicitudes,
    required this.totalActivas,
    required this.espaciosDisponibles,
    required this.tieneEmpresaConfirmada,
    required this.puedeCrearSolicitud,
    required this.puedeRegistrarEmpresaPropia,
  });

  final int limiteSolicitudes;
  final int totalActivas;
  final int espaciosDisponibles;
  final bool tieneEmpresaConfirmada;
  final bool puedeCrearSolicitud;
  final bool puedeRegistrarEmpresaPropia;

  factory ResumenSolicitudesModel.fromJson(Map<String, dynamic> json) {
    final limit = _intValue(json['limiteSolicitudes']);
    final active = _intValue(json['totalActivas']);
    final available = _intValue(json['espaciosDisponibles']);
    final confirmed = json['tieneEmpresaConfirmada'];
    final canCreate = json['puedeCrearSolicitud'];
    final canRegisterOwn = json['puedeRegistrarEmpresaPropia'];
    if (limit == null ||
        active == null ||
        available == null ||
        confirmed is! bool ||
        canCreate is! bool ||
        canRegisterOwn is! bool) {
      throw const FormatException(
        'El resumen de solicitudes no tiene un formato válido.',
      );
    }
    return ResumenSolicitudesModel(
      limiteSolicitudes: limit,
      totalActivas: active,
      espaciosDisponibles: available,
      tieneEmpresaConfirmada: confirmed,
      puedeCrearSolicitud: canCreate,
      puedeRegistrarEmpresaPropia: canRegisterOwn,
    );
  }
}

int? _intValue(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');
