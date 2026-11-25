class Apis {
  static const String baseUrl = 'http://192.168.1.10:3000';

  static final Uri login = Uri.parse('$baseUrl/api/auth/login');
  static final Uri register = Uri.parse('$baseUrl/api/auth/register');
  static final Uri forgotPassword = Uri.parse(
    '$baseUrl/api/auth/forgot-password',
  );
  static final Uri verifyResetCode = Uri.parse(
    '$baseUrl/api/auth/verify-reset-code',
  );
  static final Uri resetPassword = Uri.parse(
    '$baseUrl/api/auth/reset-password',
  );
  static final Uri currentUser = Uri.parse('$baseUrl/api/usuarios/me');
  static final Uri companies = Uri.parse('$baseUrl/api/empresas');
  static final Uri notifications = Uri.parse('$baseUrl/api/notificaciones');
  static final Uri unreadNotifications = Uri.parse(
    '$baseUrl/api/notificaciones/no-leidas',
  );
  static final Uri markAllNotificationsRead = Uri.parse(
    '$baseUrl/api/notificaciones/leer-todas',
  );
}
