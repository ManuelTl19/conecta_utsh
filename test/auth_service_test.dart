import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_utsh/helpers/apis.dart';
import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/models/password_reset_model.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';
import 'package:conecta_utsh/modules/app/services/token_store.dart';

void main() {
  test('password recovery endpoints are declared in the API catalog', () {
    expect(Apis.forgotPassword.path, '/api/auth/forgot-password');
    expect(Apis.resetPassword.path, '/api/auth/reset-password');
  });

  test('auth service consumes both password recovery endpoints', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final forgotRequest = Completer<Map<String, dynamic>>();
    final resetRequest = Completer<Map<String, dynamic>>();
    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      if (request.uri.path == '/api/auth/forgot-password') {
        forgotRequest.complete(body);
        request.response.statusCode = HttpStatus.ok;
        request.response.write('{"message":"Código enviado"}');
      } else if (request.uri.path == '/api/auth/reset-password') {
        resetRequest.complete(body);
        request.response.statusCode = HttpStatus.ok;
        request.response.write('{"message":"Contraseña actualizada"}');
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final baseUri = Uri.parse(
      'http://${server.address.address}:${server.port}',
    );
    final service = AuthService(
      forgotPasswordEndpoint: baseUri.resolve('/api/auth/forgot-password'),
      resetPasswordEndpoint: baseUri.resolve('/api/auth/reset-password'),
      tokenStore: _MemoryTokenStore(),
    );
    addTearDown(service.close);

    final forgotResponse = await service.forgotPassword(
      const ForgotPasswordRequest(email: 'juan@example.com'),
    );
    expect(await forgotRequest.future, {'correo': 'juan@example.com'});
    expect(forgotResponse.message, 'Código enviado');

    final resetResponse = await service.resetPassword(
      const ResetPasswordRequest(
        email: 'juan@example.com',
        code: '123456',
        password: 'NuevaClave2026!',
        confirmPassword: 'NuevaClave2026!',
      ),
    );
    expect(await resetRequest.future, {
      'correo': 'juan@example.com',
      'codigo': '123456',
      'password': 'NuevaClave2026!',
      'confirmarPassword': 'NuevaClave2026!',
    });
    expect(resetResponse.message, 'Contraseña actualizada');
  });

  test('registration model omits an absent optional phone number', () {
    const model = RegisterModel(
      firstName: 'Ana',
      paternalSurname: 'López',
      maternalSurname: 'Pérez',
      enrollment: '12345678',
      direction: 'Tecnologías de la Información',
      career: 'Ingeniería en Desarrollo y Gestión de Software',
      semester: 7,
      email: 'ana@example.com',
      password: 'secure-password',
      confirmPassword: 'secure-password',
    );

    expect(model.toJson().containsKey('telefono'), isFalse);
  });

  test(
    'auth service sends registration data and surfaces API errors',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      final registerRequest = Completer<Map<String, dynamic>>();
      final registerContentType = Completer<String?>();
      final loginRequest = Completer<Map<String, dynamic>>();
      final loginContentType = Completer<String?>();
      server.listen((request) async {
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        if (request.uri.path == '/api/auth/register') {
          registerRequest.complete(body);
          registerContentType.complete(request.headers.contentType?.mimeType);
          request.response.statusCode = HttpStatus.created;
          request.response.write('{}');
        } else if (request.uri.path == '/api/auth/login' &&
            body['correo'] == 'juan@example.com') {
          loginRequest.complete(body);
          loginContentType.complete(request.headers.contentType?.mimeType);
          request.response.statusCode = HttpStatus.ok;
          request.response.write(
            jsonEncode({
              'message': 'Inicio de sesión correcto',
              'token': 'test-jwt-token',
              'usuario': {
                'id': 'user-id',
                'nombre': 'Juan',
                'correo': 'juan@example.com',
                'rol': 'estudiante',
                'direccion': 'Tecnologías de la Información',
                'carrera': 'Ingeniería en Desarrollo y Gestión de Software',
              },
            }),
          );
        } else {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('{"message":"Credenciales incorrectas"}');
        }
        await request.response.close();
      });

      final endpoint = Uri.parse(
        'http://${server.address.address}:${server.port}',
      );
      final service = AuthService(
        loginEndpoint: endpoint.resolve('/api/auth/login'),
        registerEndpoint: endpoint.resolve('/api/auth/register'),
        tokenStore: _MemoryTokenStore(),
      );
      addTearDown(service.close);

      await service.register(
        const RegisterModel(
          firstName: 'Ana',
          paternalSurname: 'López',
          maternalSurname: 'Pérez',
          enrollment: '12345678',
          direction: 'Tecnologías de la Información',
          career: 'Ingeniería en Desarrollo y Gestión de Software',
          semester: 7,
          email: 'ana@example.com',
          phone: '7711234567',
          password: 'secure-password',
          confirmPassword: 'secure-password',
        ),
      );
      expect(await registerRequest.future, {
        'nombre': 'Ana',
        'apellidoPaterno': 'López',
        'apellidoMaterno': 'Pérez',
        'matricula': '12345678',
        'direccion': 'Tecnologías de la Información',
        'carrera': 'Ingeniería en Desarrollo y Gestión de Software',
        'cuatrimestre': 7,
        'correo': 'ana@example.com',
        'telefono': '7711234567',
        'password': 'secure-password',
        'confirmarPassword': 'secure-password',
      });
      expect(await registerContentType.future, 'application/json');

      final loginResponse = await service.login(
        const LoginModel(
          email: 'juan@example.com',
          password: 'MiClaveSegura123',
        ),
      );
      expect(await loginRequest.future, {
        'correo': 'juan@example.com',
        'password': 'MiClaveSegura123',
      });
      expect(await loginContentType.future, 'application/json');
      expect(loginResponse.message, 'Inicio de sesión correcto');
      expect(loginResponse.token, 'test-jwt-token');
      expect(loginResponse.user.name, 'Juan');
      expect(
        loginResponse.user.academicDirection,
        'Tecnologías de la Información',
      );
      expect(loginResponse.user.isInformationTechnologyCareer, isTrue);
      expect(loginResponse.user.location, isNull);
      expect(await service.authorizationHeaders(), {
        HttpHeaders.authorizationHeader: 'Bearer test-jwt-token',
      });

      await expectLater(
        service.login(
          const LoginModel(
            email: 'bad@example.com',
            password: 'wrong-password',
          ),
        ),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Credenciales incorrectas',
              ),
        ),
      );
      await service.logout();
      await expectLater(service.authorizationHeaders(), throwsStateError);
    },
  );
}

class _MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<void> save(String token) async {
    this.token = token;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async {
    token = null;
  }
}
