class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'correo': email};
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({this.message});

  final String? message;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponse(message: json['message']?.toString());
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.password,
    required this.confirmPassword,
  });

  final String email;
  final String code;
  final String password;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'correo': email,
    'codigo': code,
    'password': password,
    'confirmarPassword': confirmPassword,
  };
}

class ResetPasswordResponse {
  const ResetPasswordResponse({this.message});

  final String? message;

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ResetPasswordResponse(message: json['message']?.toString());
}
