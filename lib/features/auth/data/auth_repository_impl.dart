import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/login_result.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResult> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'senha': senha, 'tipo': 'nutriz'},
      );
      final data = response.data!;
      return LoginResult(
        token: data['accessToken'] as String,
        tipo: data['tipo'] as String,
        id: data['id'] as int,
        nome: data['nome'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthFailure('E-mail ou senha inválidos.');
      }
      throw const AuthFailure(
        'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});
