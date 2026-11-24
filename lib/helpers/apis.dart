class Apis {
  static const String baseUrl =
      'https://ominous-yodel-5gxq6j4g997j3vq67-3000.app.github.dev';

  static final Uri login = Uri.parse('$baseUrl/api/auth/login');
  static final Uri register = Uri.parse('$baseUrl/api/auth/register');
  static final Uri forgotPassword = Uri.parse(
    '$baseUrl/api/auth/forgot-password',
  );
  static final Uri resetPassword = Uri.parse(
    '$baseUrl/api/auth/reset-password',
  );
}
