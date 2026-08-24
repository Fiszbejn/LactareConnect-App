import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controller.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  // Só em debug: imprime request/response/erro no console do `flutter run`.
  // Sem isso, uma falha de rede vira só a mensagem genérica da UI — não dá
  // pra saber se foi timeout, conexão recusada, 500 etc.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  dio.interceptors.add(
    AuthInterceptor(
      ref.read(tokenStorageProvider),
      onUnauthorized: () => ref.read(sessionControllerProvider.notifier).logOut(),
    ),
  );

  return dio;
});
