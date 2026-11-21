class LoginModel {
  const LoginModel({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'correo': email, 'password': password};
}
