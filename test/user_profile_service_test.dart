import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_utsh/modules/app/models/user_profile_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';
import 'package:conecta_utsh/modules/app/services/user_profile_service.dart';

void main() {
  test(
    'profile mock keeps editable changes and preserves protected values',
    () async {
      final authService = AuthService(tokenStore: _MemoryTokenStore());
      final profileService = UserProfileService(authService: authService);
      addTearDown(profileService.close);
      addTearDown(authService.close);

      final original = await profileService.getCurrentUser();
      await profileService.updateCurrentUser(
        UserProfileUpdate(
          nombre: 'Ana',
          apellidoPaterno: 'García',
          apellidoMaterno: 'Ruiz',
          telefono: '',
          direccion: 'Tecnologías de la Información',
          carrera: 'Ingeniería en Desarrollo y Gestión de Software',
          cuatrimestre: 8,
        ),
      );

      final updated = await profileService.getCurrentUser();
      expect(updated.nombreCompleto, 'Ana García Ruiz');
      expect(updated.telefono, isNull);
      expect(updated.cuatrimestre, 8);
      expect(updated.correo, original.correo);
      expect(updated.matricula, original.matricula);
      expect(updated.favoriteCount, original.favoriteCount);
    },
  );

  test('profile update serializes only editable fields', () {
    const update = UserProfileUpdate(
      nombre: 'Ana',
      apellidoPaterno: 'García',
      apellidoMaterno: 'Ruiz',
      telefono: '7711234567',
      direccion: 'Tecnologías de la Información',
      carrera: 'Ingeniería en Desarrollo y Gestión de Software',
      cuatrimestre: 8,
    );

    expect(update.toJson().keys.toSet(), {
      'nombre',
      'apellidoPaterno',
      'apellidoMaterno',
      'telefono',
      'direccion',
      'carrera',
      'cuatrimestre',
    });
    expect(update.toJson().containsKey('correo'), isFalse);
    expect(update.toJson().containsKey('matricula'), isFalse);
    expect(update.toJson().containsKey('rol'), isFalse);
    expect(update.toJson().containsKey('favoritos'), isFalse);
    expect(update.toJson().containsKey('passwordHash'), isFalse);
  });
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String token) async {}

  @override
  Future<void> clear() async {}
}
