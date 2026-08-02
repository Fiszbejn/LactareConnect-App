import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/auth_failure.dart';
import '../domain/cadastro_repository.dart';
import '../domain/cadastro_request.dart';

class CadastroRepositoryImpl implements CadastroRepository {
  CadastroRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<int> registerNutriz(CadastroRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/nutrizes',
        data: {
          'nome': request.nome,
          'cpf': request.cpf,
          'dataNascimento': request.dataNascimento,
          'telefone': request.telefone,
          'email': request.email,
          'senha': request.senha,
        },
      );
      return response.data!['id'] as int;
    } on DioException catch (e) {
      throw _mapCadastroError(e);
    }
  }

  @override
  Future<void> registerEndereco(int nutrizId, CadastroRequest request) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/enderecos',
        data: {
          'cep': request.cep,
          'rua': request.rua,
          'numero': request.numero,
          'bairro': request.bairro,
          'cidade': request.cidade,
          'uf': request.uf,
          'nutrizId': nutrizId,
        },
      );
    } on DioException catch (e) {
      throw _mapCadastroError(e);
    }
  }

  AuthFailure _mapCadastroError(DioException e) {
    if (e.response?.statusCode == 409) {
      return const AuthFailure('Já existe uma conta com este CPF ou e-mail.');
    }
    if (e.response?.statusCode == 400) {
      return const AuthFailure(
        'Verifique os dados informados e tente novamente.',
      );
    }
    return const AuthFailure(
      'Não foi possível concluir o cadastro. Verifique sua conexão e tente novamente.',
    );
  }
}

final cadastroRepositoryProvider = Provider<CadastroRepository>((ref) {
  return CadastroRepositoryImpl(ref.watch(dioProvider));
});
