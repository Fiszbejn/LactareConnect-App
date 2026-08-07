import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Configuração de conexão com o backend (NestJS, versionado em `/v1`).
class ApiConstants {
  ApiConstants._();

  /// No emulador Android, "localhost" aponta pro próprio emulador, não
  /// pra máquina onde o backend está rodando — o emulador usa o alias
  /// especial `10.0.2.2` pra alcançar o host. iOS simulator, desktop e
  /// web não têm essa camada de rede virtual, então `localhost` funciona
  /// direto (checa `kIsWeb` antes de `Platform.isAndroid` porque `dart:io`
  /// não existe no target web).
  static String get baseUrl {
    final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000/v1';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
