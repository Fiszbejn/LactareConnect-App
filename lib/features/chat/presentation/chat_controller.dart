import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/chat_repository_impl.dart';
import '../domain/chat_failure.dart';
import '../domain/mensagem_chat.dart';

class ChatState {
  const ChatState({this.mensagens = const [], this.enviando = false, this.erro});

  final List<MensagemChat> mensagens;
  final bool enviando;
  final String? erro;
}

/// Dona da conversa da sessão atual — guarda as mensagens só em memória
/// (nada é relido do backend, ver domain/chat_repository.dart). A conversa
/// é criada sob demanda na primeira mensagem enviada, não na abertura da
/// tela, pra não gerar `Conversa`s vazias no backend só de a nutriz abrir
/// a aba Chat sem escrever nada.
class ChatController extends Notifier<ChatState> {
  int? _conversaId;
  int? _nutrizIdVista;
  int _proximoIdTemporario = -1;

  @override
  ChatState build() {
    // `_conversaId`/`state.mensagens` são um cache em memória deste
    // controller — sem isso, uma troca de conta sem reiniciar o app
    // (logout de A, login de B, mesma sessão do processo) deixaria B
    // vendo as mensagens de A na tela, e mandando mensagem pra uma
    // conversa que não é dela (o backend rejeitaria com 403).
    _nutrizIdVista = ref.read(sessionControllerProvider).nutrizId;
    ref.listen(sessionControllerProvider, (previous, next) {
      if (next.nutrizId != _nutrizIdVista) {
        _nutrizIdVista = next.nutrizId;
        _conversaId = null;
        state = const ChatState();
      }
    });
    return const ChatState();
  }

  Future<void> enviar(String textoDigitado) async {
    final texto = textoDigitado.trim();
    if (texto.isEmpty || state.enviando) return;

    final mensagemOtimista = MensagemChat(
      id: _proximoIdTemporario--,
      remetente: RemetenteMensagem.usuario,
      texto: texto,
      timestamp: DateTime.now(),
    );
    state = ChatState(mensagens: [...state.mensagens, mensagemOtimista], enviando: true);
    try {
      final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
      final repository = ref.read(chatRepositoryProvider);
      _conversaId ??= await repository.iniciarConversa(nutrizId);
      final resultado = await repository.enviarMensagem(conversaId: _conversaId!, texto: texto);
      state = ChatState(
        mensagens: [
          for (final mensagem in state.mensagens)
            if (mensagem.id != mensagemOtimista.id) mensagem,
          resultado.mensagemUsuario,
          resultado.respostaBot,
        ],
      );
    } on ChatFailure catch (e) {
      state = ChatState(
        mensagens: [
          for (final mensagem in state.mensagens)
            if (mensagem.id != mensagemOtimista.id) mensagem,
        ],
        erro: e.message,
      );
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
