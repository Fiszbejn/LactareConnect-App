import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/faq_repository.dart';
import '../domain/pergunta_frequente.dart';

class FaqRepositoryImpl implements FaqRepository {
  FaqRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<PerguntaFrequente>> getPerguntas() async {
    final response = await _dio.get<List<dynamic>>('/perguntas-frequentes');
    final perguntas = response.data!
        .cast<Map<String, dynamic>>()
        .map(
          (json) => PerguntaFrequente(
            id: json['id'] as int,
            categoria: json['categoria'] as String,
            pergunta: json['pergunta'] as String,
            resposta: json['resposta'] as String,
            ordem: json['ordem'] as int,
          ),
        )
        .toList();
    perguntas.sort((a, b) => a.ordem.compareTo(b.ordem));
    return perguntas;
  }

  @override
  Future<void> enviarFeedback({
    required int perguntaId,
    required bool util,
    required int nutrizId,
  }) async {
    await _dio.post<void>(
      '/feedbacks-faq',
      data: {'perguntaId': perguntaId, 'util': util, 'nutrizId': nutrizId},
    );
  }
}

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepositoryImpl(ref.watch(dioProvider));
});
