/// Configuração de conexão com o backend (NestJS, versionado em `/v1`).
class ApiConstants {
  ApiConstants._();

  /// Backend em produção (Render) — fixo em vez de apontar pro localhost/
  /// emulador porque o deploy já está no ar, então não depende de quem
  /// avalia o app ter o backend rodando localmente via Docker.
  static const baseUrl = 'https://lactareconnect-backend.onrender.com/v1';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
