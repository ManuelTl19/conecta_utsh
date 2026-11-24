class Apis {
  static const String baseUrl ='https://cuddly-happiness-pjprv4prrv562r74-3000.app.github.dev';

  static final Uri login = Uri.parse('$baseUrl/api/auth/login');
  static final Uri register = Uri.parse('$baseUrl/api/auth/register');
  static final Uri forgotPassword = Uri.parse(
    '$baseUrl/api/auth/forgot-password',
  );
  static final Uri resetPassword = Uri.parse(
    '$baseUrl/api/auth/reset-password',
  );
}
