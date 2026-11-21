class RegisterModel {
  const RegisterModel({
    required this.firstName,
    required this.paternalSurname,
    required this.maternalSurname,
    required this.enrollment,
    required this.direction,
    required this.career,
    required this.semester,
    required this.email,
    this.phone,
    required this.password,
    required this.confirmPassword,
  });

  final String firstName;
  final String paternalSurname;
  final String maternalSurname;
  final String enrollment;
  final String direction;
  final String career;
  final int semester;
  final String email;
  final String? phone;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'nombre': firstName,
    'apellidoPaterno': paternalSurname,
    'apellidoMaterno': maternalSurname,
    'matricula': enrollment,
    'direccion': direction,
    'carrera': career,
    'cuatrimestre': semester,
    'correo': email,
    if (phone != null && phone!.isNotEmpty) 'telefono': phone,
    'password': password,
    'confirmarPassword': confirmPassword,
  };
}
