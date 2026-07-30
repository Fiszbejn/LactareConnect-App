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
  Future<void> register(CadastroRequest request) async {
    try {
      final nutrizResponse = await _dio.post<Map<String, dynamic>>(
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
      final nutrizId = nutrizResponse.data!['id'] as int;

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
      if (e.response?.statusCode == 409) {
        throw const AuthFailure('Já existe uma conta com este CPF ou e-mail.');
      }
      if (e.response?.statusCode == 400) {
        throw const AuthFailure(
          'Verifique os dados informados e tente novamente.',
        );
      }
      throw const AuthFailure(
        'Não foi possível concluir o cadastro. Verifique sua conexão e tente novamente.',
      );
    }
  }
}

final cadastroRepositoryProvider = Provider<CadastroRepository>((ref) {
  return CadastroRepositoryImpl(ref.watch(dioProvider));
});
