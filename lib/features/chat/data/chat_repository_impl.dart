import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/chat_failure.dart';
import '../domain/chat_repository.dart';
import '../domain/mensagem_chat.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<int> iniciarConversa(int nutrizId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/conversas',
        data: {'nutrizId': nutrizId},
      );
      return response.data!['id'] as int;
    } on DioException catch (e) {
      throw ChatFailure(_mensagemDoBackend(e) ?? 'Não foi possível iniciar a conversa. Tente novamente.');
    }
  }

  @override
  Future<EnvioMensagemResultado> enviarMensagem({
    required int conversaId,
    required String texto,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/conversas/$conversaId/mensagens',
        data: {'texto': texto},
      );
      final data = response.data!;
      return EnvioMensagemResultado(
        mensagemUsuario: _mensagemFromJson(data['mensagemUsuario'] as Map<String, dynamic>),
        respostaBot: _mensagemFromJson(data['respostaBot'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ChatFailure(_mensagemDoBackend(e) ?? 'Não foi possível enviar a mensagem. Tente novamente.');
    }
  }

  MensagemChat _mensagemFromJson(Map<String, dynamic> json) => MensagemChat(
    id: json['id'] as int,
    remetente: remetenteMensagemFromBackend(json['remetente'] as String),
    texto: json['texto'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  /// O backend já lança as exceptions (400/403/404) com mensagem pronta em
  /// português — repassa direto em vez de traduzir de novo.
  String? _mensagemDoBackend(DioException e) {
    final codigo = e.response?.statusCode;
    if (codigo != 400 && codigo != 403 && codigo != 404) return null;
    final data = e.response?.data;
    final mensagem = data is Map ? data['message'] : null;
    return mensagem is String ? mensagem : null;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(dioProvider));
});
