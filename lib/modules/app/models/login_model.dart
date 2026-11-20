class LoginModel {
  const LoginModel({required this.enrollment, required this.password});

  final String enrollment;
  final String password;

  Map<String, dynamic> toJson() => {
    'enrollment': enrollment,
    'password': password,
  };
}
