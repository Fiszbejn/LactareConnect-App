import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Injeta `Authorization: Bearer <token>` em toda requisição e limpa a
/// sessão quando o backend responde 401 (token expirado/inválido/RBAC
/// negado) — assim nenhuma tela/repositório precisa tratar isso na mão.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.deleteToken();
      // A navegação de volta pro login acontece no `redirect` do
      // go_router (próximo passo), reagindo à ausência de token — não é
      // responsabilidade do interceptor conhecer rotas/telas.
    }
    handler.next(err);
  }
}
