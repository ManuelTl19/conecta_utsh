class LoginResponseModel {
  const LoginResponseModel({
    required this.message,
    required this.token,
    required this.user,
  });

  final String message;
  final String token;
  final LoginUserModel user;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    final token = json['token'];
    final user = json['usuario'];

    if (message is! String || message.isEmpty) {
      throw const FormatException(
        'La respuesta de inicio no contiene message.',
      );
    }
    if (token is! String || token.isEmpty) {
      throw const FormatException('La respuesta de inicio no contiene token.');
    }
    if (user is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta de inicio no contiene usuario.',
      );
    }

    return LoginResponseModel(
      message: message,
      token: token,
      user: LoginUserModel.fromJson(user),
    );
  }
}

class LoginUserModel {
  const LoginUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.career,
    this.academicDirection,
    this.location,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? career;
  final String? academicDirection;
  final String? location;

  bool get isInformationTechnologyCareer {
    final normalizedCareer = '${career ?? ''} ${academicDirection ?? ''}'
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    return RegExp(
      r'tecnolog|informat|sistemas|software|computacion|ciberseguridad|telematica|\bti\b',
    ).hasMatch(normalizedCareer);
  }

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nombre'];
    final email = json['correo'];
    final role = json['rol'];
    final career = json['carrera'];
    final academicDirection = json['direccion'];
    final location = json['ubicacion'] ?? json['estado'] ?? json['ciudad'];

    if (id == null || name is! String || email is! String || role is! String) {
      throw const FormatException(
        'Los datos de usuario en la respuesta de inicio no son válidos.',
      );
    }

    return LoginUserModel(
      id: id.toString(),
      name: name,
      email: email,
      role: role,
      career: career is String ? career : null,
      academicDirection: academicDirection is String
          ? academicDirection
          : null,
      location: location is String ? location : null,
    );
  }
}
