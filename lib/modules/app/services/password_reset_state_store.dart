import 'package:shared_preferences/shared_preferences.dart';

class PasswordResetState {
  const PasswordResetState({required this.email, required this.expiresAt});

  final String email;
  final DateTime expiresAt;

  Duration get remaining => expiresAt.difference(DateTime.now());
}

class PasswordResetStateStore {
  static const _emailKey = 'passwordResetEmail';
  static const _expiresAtKey = 'passwordResetExpiresAt';

  Future<void> save(PasswordResetState state) async {
    final preferences = await SharedPreferences.getInstance();
    final savedEmail = await preferences.setString(_emailKey, state.email);
    final savedExpiration = await preferences.setString(
      _expiresAtKey,
      state.expiresAt.toIso8601String(),
    );
    if (!savedEmail || !savedExpiration) {
      throw StateError('No se pudo guardar el estado del código.');
    }
  }

  Future<PasswordResetState?> readActive() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_emailKey);
    final expiration = preferences.getString(_expiresAtKey);
    if (email == null || expiration == null) {
      await clear();
      return null;
    }

    final expiresAt = DateTime.tryParse(expiration);
    if (email.isEmpty ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      await clear();
      return null;
    }

    return PasswordResetState(email: email, expiresAt: expiresAt);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final removedEmail = await preferences.remove(_emailKey);
    final removedExpiration = await preferences.remove(_expiresAtKey);
    if (!removedEmail || !removedExpiration) {
      throw StateError('No se pudo limpiar el estado del código.');
    }
  }
}
