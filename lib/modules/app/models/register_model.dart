class RegisterModel {
  const RegisterModel({
    required this.firstName,
    required this.paternalSurname,
    required this.maternalSurname,
    required this.enrollment,
    required this.career,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String firstName;
  final String paternalSurname;
  final String maternalSurname;
  final String enrollment;
  final String career;
  final String email;
  final String phone;
  final String password;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'paternalSurname': paternalSurname,
    'maternalSurname': maternalSurname,
    'enrollment': enrollment,
    'career': career,
    'email': email,
    'phone': phone,
    'password': password,
  };
}
