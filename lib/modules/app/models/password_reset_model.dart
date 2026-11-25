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

class VerifyResetCodeRequest {
  const VerifyResetCodeRequest({required this.email, required this.code});

  final String email;
  final String code;

  Map<String, dynamic> toJson() => {'correo': email, 'codigo': code};
}

class VerifyResetCodeResponse {
  const VerifyResetCodeResponse({
    required this.message,
    required this.resetToken,
    required this.expiresInSeconds,
  });

  final String message;
  final String resetToken;
  final int expiresInSeconds;

  factory VerifyResetCodeResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    final resetToken = json['resetToken'];
    final expiresInSeconds = json['expiraEnSegundos'];
    if (message is! String ||
        resetToken is! String ||
        resetToken.isEmpty ||
        expiresInSeconds is! int ||
        expiresInSeconds <= 0) {
      throw const FormatException(
        'La respuesta de verificación del código no es válida.',
      );
    }

    return VerifyResetCodeResponse(
      message: message,
      resetToken: resetToken,
      expiresInSeconds: expiresInSeconds,
    );
  }
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String email;
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'correo': email,
    'resetToken': resetToken,
    'nuevaPassword': newPassword,
    'confirmarPassword': confirmPassword,
  };
}

class ResetPasswordResponse {
  const ResetPasswordResponse({this.message});

  final String? message;

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) =>
      ResetPasswordResponse(message: json['message']?.toString());
}
