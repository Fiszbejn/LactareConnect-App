import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/nutriz_resumo.dart';
import '../domain/recompensa.dart';
import '../domain/recompensas_repository.dart';
import '../domain/resgate.dart';
import '../domain/resgate_failure.dart';

class RecompensasRepositoryImpl implements RecompensasRepository {
  RecompensasRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Recompensa>> getRecompensas() async {
    final response = await _dio.get<List<dynamic>>('/recompensas');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(
          (json) => Recompensa(
            id: json['id'] as int,
            nome: json['nome'] as String,
            parceiro: json['parceiro'] as String,
            categoria: json['categoria'] as String,
            custoGotinhas: json['custoGotinhas'] as int,
            estoque: json['estoque'] as int,
            ativo: json['ativo'] as bool,
            imagemUrl: json['imagemUrl'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<NutrizResumo> getNutrizResumo(int nutrizId) async {
    final response = await _dio.get<Map<String, dynamic>>('/nutrizes/$nutrizId');
    final json = response.data!;
    return NutrizResumo(
      saldoGotinhas: json['saldoGotinhas'] as int,
      enderecoId: json['enderecoId'] as int?,
    );
  }

  @override
  Future<String> getEnderecoResumo(int enderecoId) async {
    final response = await _dio.get<Map<String, dynamic>>('/enderecos/$enderecoId');
    final json = response.data!;
    return '${json['rua']}, ${json['numero']} · ${json['bairro']} · '
        '${json['cidade']}/${json['uf']}';
  }

  @override
  Future<List<Resgate>> getMeusResgates() async {
    final response = await _dio.get<List<dynamic>>('/resgates');
    final resgates = response.data!
        .cast<Map<String, dynamic>>()
        .map(
          (json) => Resgate(
            id: json['id'] as int,
            status: resgateStatusFromString(json['status'] as String),
            enderecoEntrega: json['enderecoEntrega'] as String?,
            data: DateTime.parse(json['data'] as String),
            recompensaId: json['recompensaId'] as int?,
          ),
        )
        .toList();
    resgates.sort((a, b) => b.data.compareTo(a.data));
    return resgates;
  }

  @override
  Future<void> criarResgate({
    required int nutrizId,
    required int recompensaId,
    String? enderecoEntrega,
  }) async {
    try {
      await _dio.post<void>(
        '/resgates',
        data: {
          'nutrizId': nutrizId,
          'recompensaId': recompensaId,
          'enderecoEntrega': ?enderecoEntrega,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // O backend já lança BadRequestException com mensagem pronta em
        // português (saldo insuficiente / sem estoque / inativa) — repassa
        // direto em vez de traduzir de novo.
        final data = e.response?.data;
        final mensagem = data is Map ? data['message'] : null;
        throw ResgateFailure(
          mensagem is String ? mensagem : 'Não foi possível concluir o resgate.',
        );
      }
      throw const ResgateFailure(
        'Não foi possível concluir o resgate. Verifique sua conexão e tente novamente.',
      );
    }
  }
}

final recompensasRepositoryProvider = Provider<RecompensasRepository>((ref) {
  return RecompensasRepositoryImpl(ref.watch(dioProvider));
});
