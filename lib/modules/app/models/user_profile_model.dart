class UserProfile {
  const UserProfile({
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.matricula,
    required this.direccion,
    required this.carrera,
    required this.cuatrimestre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.favoriteCount,
    required this.estadoEstadia,
    required this.citasPendientes,
    required this.citasConfirmadas,
    required this.createdAt,
  });

  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String matricula;
  final String direccion;
  final String carrera;
  final int cuatrimestre;
  final String correo;
  final String? telefono;
  final String rol;
  final int favoriteCount;
  final String? estadoEstadia;
  final int citasPendientes;
  final int citasConfirmadas;
  final String? createdAt;

  String get nombreCompleto => [
    nombre,
    apellidoPaterno,
    apellidoMaterno,
  ].where((parte) => parte.trim().isNotEmpty).join(' ');

  int get citasActivas => citasPendientes + citasConfirmadas;

  UserProfile withUpdate(UserProfileUpdate update) => UserProfile(
    nombre: update.nombre.trim(),
    apellidoPaterno: update.apellidoPaterno.trim(),
    apellidoMaterno: update.apellidoMaterno.trim(),
    matricula: matricula,
    direccion: update.direccion,
    carrera: update.carrera,
    cuatrimestre: update.cuatrimestre,
    correo: correo,
    telefono: update.telefono == null || update.telefono!.trim().isEmpty
        ? null
        : update.telefono!.trim(),
    rol: rol,
    favoriteCount: favoriteCount,
    estadoEstadia: estadoEstadia,
    citasPendientes: citasPendientes,
    citasConfirmadas: citasConfirmadas,
    createdAt: createdAt,
  );

  factory UserProfile.fromApiJson(Map<String, dynamic> json) {
    final user = json['usuario'];
    final summary = json['resumen'];
    if (user is! Map<String, dynamic> || summary is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta del perfil no contiene usuario y resumen válidos.',
      );
    }

    final favorites = user['favoritos'];
    if (favorites is! List) {
      throw const FormatException(
        'La respuesta del perfil no contiene una lista de favoritos válida.',
      );
    }

    final status = summary['estadoEstadia'];
    final pendingAppointments = summary['citasPendientes'];
    final confirmedAppointments = summary['citasConfirmadas'];
    if ((status != null && status is! String) ||
        pendingAppointments is! int ||
        confirmedAppointments is! int) {
      throw const FormatException(
        'El resumen del perfil contiene datos no válidos.',
      );
    }

    final semester = user['cuatrimestre'];
    final createdAt = user['createdAt'];
    final phone = user['telefono'];
    final requiredStrings = {
      'nombre': user['nombre'],
      'apellidoPaterno': user['apellidoPaterno'],
      'apellidoMaterno': user['apellidoMaterno'],
      'matricula': user['matricula'],
      'direccion': user['direccion'],
      'carrera': user['carrera'],
      'correo': user['correo'],
      'rol': user['rol'],
    };
    if (requiredStrings.values.any((value) => value is! String) ||
        semester is! int ||
        (phone != null && phone is! String) ||
        (createdAt != null && createdAt is! String)) {
      throw const FormatException(
        'La respuesta del perfil contiene datos de usuario no válidos.',
      );
    }

    return UserProfile(
      nombre: user['nombre'] as String,
      apellidoPaterno: user['apellidoPaterno'] as String,
      apellidoMaterno: user['apellidoMaterno'] as String,
      matricula: user['matricula'] as String,
      direccion: user['direccion'] as String,
      carrera: user['carrera'] as String,
      cuatrimestre: semester,
      correo: user['correo'] as String,
      telefono: phone as String?,
      rol: user['rol'] as String,
      favoriteCount: favorites.length,
      estadoEstadia: status as String?,
      citasPendientes: pendingAppointments,
      citasConfirmadas: confirmedAppointments,
      createdAt: createdAt as String?,
    );
  }
}

class UserProfileUpdate {
  const UserProfileUpdate({
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.telefono,
    required this.direccion,
    required this.carrera,
    required this.cuatrimestre,
  });

  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String? telefono;
  final String direccion;
  final String carrera;
  final int cuatrimestre;

  Map<String, dynamic> toJson() => {
    'nombre': nombre.trim(),
    'apellidoPaterno': apellidoPaterno.trim(),
    'apellidoMaterno': apellidoMaterno.trim(),
    'telefono': telefono == null || telefono!.trim().isEmpty
        ? null
        : telefono!.trim(),
    'direccion': direccion,
    'carrera': carrera,
    'cuatrimestre': cuatrimestre,
  };
}
