class Apis {
  static const String baseUrl ='https://improved-potato-q75v69qq7pjfx56g-3000.app.github.dev';

  static final Uri login = Uri.parse('$baseUrl/api/auth/login');
  static final Uri register = Uri.parse('$baseUrl/api/auth/register');
  static final Uri forgotPassword = Uri.parse(
    '$baseUrl/api/auth/forgot-password',
  );
  static final Uri resetPassword = Uri.parse(
    '$baseUrl/api/auth/reset-password',
  );
  static final Uri citas = Uri.parse('$baseUrl/api/citas');
  static final Uri horariosDisponibles = Uri.parse(
    '$baseUrl/api/citas/horarios-disponibles',
  );
}
