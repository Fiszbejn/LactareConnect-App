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
  static const _nutrizIdKey = 'auth_nutriz_id';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readTipo() => _storage.read(key: _tipoKey);

  /// Id da nutriz logada (`id` retornado por `POST /v1/auth/login`) —
  /// necessário pra endpoints "dono-do-registro" que exigem `nutrizId`
  /// explícito no corpo da requisição (ex: `POST /feedbacks-faq`).
  Future<int?> readNutrizId() async {
    final value = await _storage.read(key: _nutrizIdKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> saveSession({
    required String token,
    required String tipo,
    required int nutrizId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _tipoKey, value: tipo);
    await _storage.write(key: _nutrizIdKey, value: nutrizId.toString());
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tipoKey);
    await _storage.delete(key: _nutrizIdKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});
