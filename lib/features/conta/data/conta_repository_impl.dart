import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/conta_repository.dart';
import '../domain/endereco.dart';
import '../domain/nutriz_perfil.dart';
import '../domain/preferencias.dart';

class ContaRepositoryImpl implements ContaRepository {
  ContaRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<NutrizPerfil> getPerfil(int nutrizId) async {
    final response = await _dio.get<Map<String, dynamic>>('/nutrizes/$nutrizId');
    final json = response.data!;
    return NutrizPerfil(
      id: json['id'] as int,
      nome: json['nome'] as String,
      cpf: json['cpf'] as String,
      dataNascimento: DateTime.parse(json['dataNascimento'] as String),
      telefone: json['telefone'] as String,
      email: json['email'] as String,
      status: nutrizStatusFromString(json['status'] as String),
      saldoGotinhas: json['saldoGotinhas'] as int,
      dataCadastro: DateTime.parse(json['dataCadastro'] as String),
      enderecoId: json['enderecoId'] as int?,
      preferenciasId: json['preferenciasId'] as int?,
    );
  }

  @override
  Future<Endereco> getEndereco(int enderecoId) async {
    final response = await _dio.get<Map<String, dynamic>>('/enderecos/$enderecoId');
    final json = response.data!;
    return Endereco(
      id: json['id'] as int,
      cep: json['cep'] as String,
      rua: json['rua'] as String,
      numero: json['numero'] as String,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      uf: json['uf'] as String,
    );
  }

  @override
  Future<Preferencias> getPreferencias(int preferenciasId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/preferencias-usuario/$preferenciasId',
    );
    final json = response.data!;
    return Preferencias(
      id: json['id'] as int,
      notificacoesAtivas: json['notificacoesAtivas'] as bool,
      idioma: json['idioma'] as String,
    );
  }

  @override
  Future<void> atualizarPerfil({
    required int nutrizId,
    String? nome,
    String? telefone,
    String? email,
    String? senha,
  }) async {
    await _dio.patch<void>(
      '/nutrizes/$nutrizId',
      data: {
        'nome': ?nome,
        'telefone': ?telefone,
        'email': ?email,
        'senha': ?senha,
      },
    );
  }

  @override
  Future<void> atualizarEndereco({
    required int enderecoId,
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    required String cidade,
    required String uf,
  }) async {
    await _dio.patch<void>(
      '/enderecos/$enderecoId',
      data: {
        'cep': cep,
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'uf': uf,
      },
    );
  }

  @override
  Future<void> atualizarNotificacoes({
    required int preferenciasId,
    required bool notificacoesAtivas,
  }) async {
    await _dio.patch<void>(
      '/preferencias-usuario/$preferenciasId',
      data: {'notificacoesAtivas': notificacoesAtivas},
    );
  }
}

final contaRepositoryProvider = Provider<ContaRepository>((ref) {
  return ContaRepositoryImpl(ref.watch(dioProvider));
});
