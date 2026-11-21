import 'package:conecta_utsh/helpers/providers/providers.dart';

class SettingsService {
  const SettingsService();

  static const _defaults = <String, bool>{
    'push_notifications': true,
    'email_notifications': true,
    'job_alerts': true,
    'sound_vibration': false,
  };

  Future<Map<String, bool>> loadToggleValues() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return {
      for (final entry in _defaults.entries)
        entry.key: prefs.getBool('settings_${entry.key}') ?? entry.value,
    };
  }

  Future<void> saveToggleValue(String id, bool value) async {
    if (!_defaults.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'La opción no es persistible.');
    }
    final saved = await prefs.setBool('settings_$id', value);
    if (!saved) {
      throw StateError('No se pudo guardar la preferencia "$id".');
    }
  }
}
