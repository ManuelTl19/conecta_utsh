import 'dart:convert';

import 'package:conecta_utsh/helpers/providers/providers.dart';
import 'package:conecta_utsh/modules/app/models/user_preferences_model.dart';

class UserPreferencesService {
  const UserPreferencesService();

  String _key(String name, String userId) => '${name}_$userId';

  Future<bool> hasSeen(String userId) async =>
      prefs.getBool(_key('preferencias_vistas', userId)) ?? false;

  Future<String?> getStatus(String userId) async =>
      prefs.getString(_key('preferencias_estado', userId));

  Future<UserPreferencesModel?> getPreferences(String userId) async {
    final value = prefs.getString(_key('preferencias_datos', userId));
    if (value == null) return null;

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Las preferencias guardadas no son válidas.');
    }
    return UserPreferencesModel.fromJson(decoded);
  }

  Future<void> save({
    required String userId,
    required UserPreferencesModel preferences,
    required String status,
  }) async {
    if (status != 'completado' && status != 'omitido') {
      throw ArgumentError.value(status, 'status', 'Estado no válido.');
    }

    final savedPreferences = await prefs.setString(
      _key('preferencias_datos', userId),
      jsonEncode(preferences.toJson()),
    );
    if (!savedPreferences) {
      throw StateError('No se pudieron guardar tus preferencias.');
    }

    final savedStatus = await prefs.setString(
      _key('preferencias_estado', userId),
      status,
    );
    if (!savedStatus) {
      throw StateError('No se pudo guardar el estado de tus preferencias.');
    }

    final savedSeen = await prefs.setBool(
      _key('preferencias_vistas', userId),
      true,
    );
    if (!savedSeen) {
      throw StateError('No se pudo guardar el avance de tus preferencias.');
    }
  }
}
