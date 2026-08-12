import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/agendamento.dart';
import '../domain/regiao_atendimento.dart';
import '../domain/doacao_failure.dart';
import '../domain/doacao_repository.dart';
import '../domain/exame_pre_doacao.dart';

class DoacaoRepositoryImpl implements DoacaoRepository {
  DoacaoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<RegiaoAtendimento>> getRegioesAtendimento() async {
    final response = await _dio.get<List<dynamic>>('/regioes-atendimento');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(
          (json) => RegiaoAtendimento(
            id: json['id'] as int,
            nome: json['nome'] as String,
            enderecoTexto: json['enderecoTexto'] as String,
            areaAtendimento: json['areaAtendimento'] as String,
            latitude: (json['latitude'] as num?)?.toDouble(),
            longitude: (json['longitude'] as num?)?.toDouble(),
          ),
        )
        .toList();
  }

  @override
  Future<List<ExamePreDoacao>> getMeusExames() async {
    final response = await _dio.get<List<dynamic>>('/exames-pre-doacao');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(_examePreDoacaoFromJson)
        // Descarta linhas de tipos fora dos 4 obrigatórios (ver domain/exame_pre_doacao.dart).
        .whereType<ExamePreDoacao>()
        .toList();
  }

  ExamePreDoacao? _examePreDoacaoFromJson(Map<String, dynamic> json) {
    final tipo = exameTipoFromBackend(json['tipoExame'] as String);
    if (tipo == null) return null;
    final dataEnvio = json['dataEnvio'] as String?;
    return ExamePreDoacao(
      id: json['id'] as int,
      tipoExame: tipo,
      status: exameStatusFromBackend(json['status'] as String),
      arquivoUrl: json['arquivoUrl'] as String?,
      dataEnvio: dataEnvio != null ? DateTime.parse(dataEnvio) : null,
    );
  }

  @override
  Future<void> enviarExame({
    required int nutrizId,
    required ExameTipo tipo,
    required String arquivoUrl,
    int? exameIdExistente,
  }) async {
    try {
      if (exameIdExistente != null) {
        await _dio.patch<void>(
          '/exames-pre-doacao/$exameIdExistente',
          data: {'status': 'ok', 'arquivoUrl': arquivoUrl},
        );
      } else {
        await _dio.post<void>(
          '/exames-pre-doacao',
          data: {
            'tipoExame': tipo.valorBackend,
            'status': 'ok',
            'arquivoUrl': arquivoUrl,
            'nutrizId': nutrizId,
          },
        );
      }
    } on DioException catch (e) {
      throw DoacaoFailure(_mensagemDoBackend(e) ?? 'Não foi possível enviar o exame. Tente novamente.');
    }
  }

  @override
  Future<void> criarAgendamento({
    required int nutrizId,
    required int regiaoAtendimentoId,
    required DateTime dataColeta,
    required String horario,
  }) async {
    try {
      await _dio.post<void>(
        '/agendamentos',
        data: {
          'dataColeta': _formatarData(dataColeta),
          'horario': horario,
          'nutrizId': nutrizId,
          'regiaoAtendimentoId': regiaoAtendimentoId,
        },
      );
    } on DioException catch (e) {
      throw DoacaoFailure(
        _mensagemDoBackend(e) ?? 'Não foi possível agendar a coleta. Tente novamente.',
      );
    }
  }

  @override
  Future<List<Agendamento>> getMeusAgendamentos() async {
    final response = await _dio.get<List<dynamic>>('/agendamentos');
    final agendamentos = response.data!
        .cast<Map<String, dynamic>>()
        .map(
          (json) => Agendamento(
            id: json['id'] as int,
            dataColeta: DateTime.parse(json['dataColeta'] as String),
            horario: json['horario'] as String,
            status: agendamentoStatusFromBackend(json['status'] as String),
            regiaoAtendimentoId: json['regiaoAtendimentoId'] as int?,
            doacaoId: json['doacaoId'] as int?,
          ),
        )
        .toList();
    agendamentos.sort((a, b) => b.dataColeta.compareTo(a.dataColeta));
    return agendamentos;
  }

  @override
  Future<void> confirmarColetaRealizada(int agendamentoId) async {
    try {
      await _dio.patch<void>(
        '/agendamentos/$agendamentoId',
        data: {'status': 'realizado'},
      );
    } on DioException catch (e) {
      throw DoacaoFailure(
        _mensagemDoBackend(e) ?? 'Não foi possível confirmar a coleta. Tente novamente.',
      );
    }
  }

  @override
  Future<void> registrarDoacao({
    required int nutrizId,
    required int agendamentoId,
    required int volumeMl,
    required DateTime dataColeta,
  }) async {
    try {
      await _dio.post<void>(
        '/doacoes',
        data: {
          'volumeMl': volumeMl,
          'dataColeta': dataColeta.toUtc().toIso8601String(),
          'nutrizId': nutrizId,
          'agendamentoId': agendamentoId,
        },
      );
    } on DioException catch (e) {
      throw DoacaoFailure(
        _mensagemDoBackend(e) ?? 'Não foi possível registrar a doação. Tente novamente.',
      );
    }
  }

  String _formatarData(DateTime data) => data.toIso8601String().split('T').first;

  /// O backend já lança as exceptions (400/409) com mensagem pronta em
  /// português — repassa direto em vez de traduzir de novo.
  String? _mensagemDoBackend(DioException e) {
    final codigo = e.response?.statusCode;
    if (codigo != 400 && codigo != 409) return null;
    final data = e.response?.data;
    final mensagem = data is Map ? data['message'] : null;
    return mensagem is String ? mensagem : null;
  }
}

final doacaoRepositoryProvider = Provider<DoacaoRepository>((ref) {
  return DoacaoRepositoryImpl(ref.watch(dioProvider));
});
