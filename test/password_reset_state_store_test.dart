import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conecta_utsh/modules/app/services/password_reset_state_store.dart';
import 'package:conecta_utsh/modules/app/services/password_validator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('password validator enforces the shared password requirements', () {
    expect(passwordValidationMessage('short1!'), 'Usa al menos 8 caracteres');
    expect(
      passwordValidationMessage('password1!'),
      'Incluye al menos una letra mayúscula',
    );
    expect(
      passwordValidationMessage('Password!'),
      'Incluye al menos un número',
    );
    expect(
      passwordValidationMessage('Password1'),
      'Incluye al menos un carácter especial',
    );
    expect(passwordValidationMessage('Password1!'), isNull);
    expect(isValidPassword('Password1!'), isTrue);
  });

  test(
    'password reset state uses the saved expiration and clears when expired',
    () async {
      final store = PasswordResetStateStore();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await store.save(
        PasswordResetState(email: 'juan@example.com', expiresAt: expiresAt),
      );
      final activeState = await store.readActive();
      expect(activeState?.email, 'juan@example.com');
      expect(activeState?.expiresAt, expiresAt);

      await store.save(
        PasswordResetState(
          email: 'juan@example.com',
          expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
      );
      expect(await store.readActive(), isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('passwordResetEmail'),
        isNull,
      );
    },
  );
}
