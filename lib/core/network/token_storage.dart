import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o JWT em armazenamento seguro do SO (Keychain no iOS, Keystore
/// no Android) — nunca em `SharedPreferences`/memória simples, que não
/// são criptografados.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
