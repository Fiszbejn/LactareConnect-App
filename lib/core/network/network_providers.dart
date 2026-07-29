import 'package:dio/dio.dart';
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

  dio.interceptors.add(
    AuthInterceptor(
      ref.read(tokenStorageProvider),
      onUnauthorized: () => ref.read(sessionControllerProvider.notifier).logOut(),
    ),
  );

  return dio;
});
