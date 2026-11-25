import 'package:conecta_utsh/modules/app/models/login_response_model.dart';

class UserProfile {
  const UserProfile({
    this.id = '',
    this.nombre = '',
    this.apellidoPaterno = '',
    this.apellidoMaterno = '',
    this.matricula = '',
    this.direccion = '',
    this.carrera = '',
    this.cuatrimestre = 0,
    this.correo = '',
    this.telefono,
    this.rol = '',
    this.favoriteCount = 0,
    this.estadoEstadia,
    this.citasPendientes = 0,
    this.citasConfirmadas = 0,
    this.createdAt,
  });

  final String id;
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
  ].where((part) => part.trim().isNotEmpty).join(' ');

  String get nombreCompletoPresentacion => nombreCompleto
      .split(RegExp(r'\s+'))
      .map(_capitalizeWord)
      .where((word) => word.isNotEmpty)
      .join(' ');

  String get iniciales {
    final first = nombre.trim().isEmpty ? '' : nombre.trim()[0];
    final paternal = apellidoPaterno.trim().isEmpty
        ? ''
        : apellidoPaterno.trim()[0];
    return '$first$paternal'.toUpperCase();
  }

  bool get esAdmin =>
      rol.trim().toLowerCase() == 'admin' ||
      rol.trim().toLowerCase() == 'administrador';

  bool get esEstudiante => rol.trim().toLowerCase() == 'estudiante';
  int get citasActivas => citasPendientes + citasConfirmadas;

  factory UserProfile.fromLogin(LoginUserModel user) {
    final nameParts = user.name.trim().split(RegExp(r'\s+'));
    return UserProfile(
      id: user.id,
      nombre: nameParts.isEmpty ? '' : nameParts.first,
      apellidoPaterno: nameParts.length > 1 ? nameParts[1] : '',
      apellidoMaterno: nameParts.length > 2 ? nameParts.skip(2).join(' ') : '',
      correo: user.email,
      rol: user.role,
      carrera: user.career ?? '',
      direccion: user.academicDirection ?? '',
    );
  }

  factory UserProfile.fromApiJson(
    Map<String, dynamic> json, {
    UserProfile? fallback,
  }) {
    final rawUser = json['usuario'];
    if (rawUser is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta del perfil no contiene un usuario válido.',
      );
    }
    final user = rawUser;
    final summary = json['resumen'];
    final favorites = user['favoritos'];
    final pending = summary is Map<String, dynamic>
        ? _intValue(summary['citasPendientes'])
        : null;
    final confirmed = summary is Map<String, dynamic>
        ? _intValue(summary['citasConfirmadas'])
        : null;
    final stayStatus = summary is Map<String, dynamic>
        ? _optionalString(summary['estadoEstadia'])
        : null;

    return UserProfile(
      id: _string(user['id'] ?? user['_id']) ?? fallback?.id ?? '',
      nombre: _string(user['nombre']) ?? fallback?.nombre ?? '',
      apellidoPaterno:
          _string(user['apellidoPaterno']) ?? fallback?.apellidoPaterno ?? '',
      apellidoMaterno:
          _string(user['apellidoMaterno']) ?? fallback?.apellidoMaterno ?? '',
      matricula: _string(user['matricula']) ?? fallback?.matricula ?? '',
      direccion: _string(user['direccion']) ?? fallback?.direccion ?? '',
      carrera: _string(user['carrera']) ?? fallback?.carrera ?? '',
      cuatrimestre:
          _intValue(user['cuatrimestre']) ?? fallback?.cuatrimestre ?? 0,
      correo: _string(user['correo']) ?? fallback?.correo ?? '',
      telefono: user.containsKey('telefono')
          ? _optionalString(user['telefono'])
          : fallback?.telefono,
      rol: _string(user['rol']) ?? fallback?.rol ?? '',
      favoriteCount: favorites is List
          ? favorites.length
          : fallback?.favoriteCount ?? 0,
      estadoEstadia: summary is Map<String, dynamic>
          ? stayStatus ?? fallback?.estadoEstadia
          : fallback?.estadoEstadia,
      citasPendientes: pending ?? fallback?.citasPendientes ?? 0,
      citasConfirmadas: confirmed ?? fallback?.citasConfirmadas ?? 0,
      createdAt: _optionalString(user['createdAt']) ?? fallback?.createdAt,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse('$value');
  }

  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}
