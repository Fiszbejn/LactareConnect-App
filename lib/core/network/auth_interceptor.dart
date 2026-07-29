import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Injeta `Authorization: Bearer <token>` em toda requisição e avisa
/// quando o backend responde 401 (token expirado/inválido/RBAC negado)
/// — quem decide o que fazer com esse aviso é [onUnauthorized], não este
/// interceptor. Isso evita o interceptor (camada `network`) conhecer
/// conceitos de sessão/estado do app (camada `session`).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, {required this.onUnauthorized});

  final TokenStorage _tokenStorage;
  final Future<void> Function() onUnauthorized;

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
      await onUnauthorized();
    }
    handler.next(err);
  }
}
