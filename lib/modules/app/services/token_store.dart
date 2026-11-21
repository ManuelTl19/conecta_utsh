import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:conecta_utsh/helpers/constants.dart';

abstract interface class TokenStore {
  Future<void> save(String token);
  Future<String?> read();
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(String token) async {
    try {
      await _storage.write(key: Constants.tokenKey, value: token);
    } on PlatformException catch (error) {
      throw TokenStorageException(
        error.message ?? 'No se pudo guardar el token de forma segura.',
      );
    }
  }

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: Constants.tokenKey);
    } on PlatformException catch (error) {
      throw TokenStorageException(
        error.message ?? 'No se pudo leer el token guardado.',
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: Constants.tokenKey);
    } on PlatformException catch (error) {
      throw TokenStorageException(
        error.message ?? 'No se pudo eliminar el token guardado.',
      );
    }
  }
}

class TokenStorageException implements Exception {
  const TokenStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
