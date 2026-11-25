enum SolicitudEstado {
  registrada('registrada', 'Registrada'),
  enProceso('en_proceso', 'En proceso'),
  aceptada('aceptada', 'Aceptada'),
  documentacionPendiente('documentacion_pendiente', 'Documentación pendiente'),
  estadiaEnCurso('estadia_en_curso', 'Estadía en curso'),
  finalizada('finalizada', 'Finalizada'),
  rechazada('rechazada', 'Rechazada'),
  cancelada('cancelada', 'Cancelada');

  const SolicitudEstado(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  bool get esActiva => switch (this) {
    registrada ||
    enProceso ||
    aceptada ||
    documentacionPendiente ||
    estadiaEnCurso => true,
    finalizada || rechazada || cancelada => false,
  };

  bool get puedeCancelarEstudiante => this == registrada || this == enProceso;

  bool get esHistorial =>
      this == finalizada || this == rechazada || this == cancelada;

  List<SolicitudEstado> get transicionesPermitidas => switch (this) {
    registrada => const [enProceso, aceptada, rechazada, cancelada],
    enProceso => const [aceptada, rechazada, cancelada],
    aceptada => const [documentacionPendiente, cancelada],
    documentacionPendiente => const [estadiaEnCurso, cancelada],
    estadiaEnCurso => const [finalizada, cancelada],
    finalizada || rechazada || cancelada => const [],
  };

  static SolicitudEstado parse(Object? value) {
    for (final estado in values) {
      if (estado.valor == value) return estado;
    }
    throw const FormatException('El estado de la solicitud no es válido.');
  }
}

enum SolicitudOrigen {
  catalogo('catalogo', 'Catálogo'),
  propia('propia', 'Empresa propia');

  const SolicitudOrigen(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static SolicitudOrigen? parse(Object? value) {
    if (value == null) return null;
    for (final origen in values) {
      if (origen.valor == value) return origen;
    }
    throw const FormatException('El origen de la solicitud no es válido.');
  }
}
