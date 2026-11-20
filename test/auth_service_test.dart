import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_utsh/modules/app/models/login_model.dart';
import 'package:conecta_utsh/modules/app/models/register_model.dart';
import 'package:conecta_utsh/modules/app/services/auth_service.dart';

void main() {
  test(
    'auth service sends registration data and surfaces API errors',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      final registerRequest = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        if (request.uri.path == '/register') {
          registerRequest.complete(body);
          request.response.statusCode = HttpStatus.created;
          request.response.write('{}');
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
        loginEndpoint: endpoint.resolve('/login'),
        registerEndpoint: endpoint.resolve('/register'),
      );
      addTearDown(service.close);

      await service.register(
        const RegisterModel(
          firstName: 'Ana',
          paternalSurname: 'López',
          maternalSurname: 'Pérez',
          enrollment: '12345678',
          career: 'Ingeniería',
          email: 'ana@example.com',
          phone: '7711234567',
          password: 'secure-password',
        ),
      );
      expect(await registerRequest.future, {
        'firstName': 'Ana',
        'paternalSurname': 'López',
        'maternalSurname': 'Pérez',
        'enrollment': '12345678',
        'career': 'Ingeniería',
        'email': 'ana@example.com',
        'phone': '7711234567',
        'password': 'secure-password',
      });

      await expectLater(
        service.login(
          const LoginModel(enrollment: '12345678', password: 'wrong-password'),
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
    },
  );
}
