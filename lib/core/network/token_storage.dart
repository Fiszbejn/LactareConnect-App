import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o JWT e o `tipo` do usuário logado (`nutriz` | `administrador`)
/// em armazenamento seguro do SO (Keychain no iOS, Keystore no Android) —
/// nunca em `SharedPreferences`/memória simples, que não são criptografados.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _tipoKey = 'auth_tipo';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readTipo() => _storage.read(key: _tipoKey);

  Future<void> saveSession({required String token, required String tipo}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _tipoKey, value: tipo);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tipoKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});
