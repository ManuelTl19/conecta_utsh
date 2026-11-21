class Apis {
  static const String baseUrl = 'http://192.168.1.10:3000';

  static final Uri login = Uri.parse('$baseUrl/api/auth/login');
  static final Uri register = Uri.parse('$baseUrl/api/auth/register');
}
