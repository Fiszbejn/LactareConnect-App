import 'mensagem_chat.dart';

/// Contrato de acesso ao chat com a Lila — a implementação real (Dio) fica
/// em `data/`.
///
/// Sem GET de histórico de propósito: `Conversa`/`Mensagem` são admin-only
/// pra leitura no backend — a conversa existe só pra auditoria, a nutriz
/// nunca relê o que já foi dito. O app guarda as mensagens da sessão atual
/// só em memória (ver presentation/chat_controller.dart); ao reabrir o
/// app, a conversa anterior já não existe mais do lado do cliente.
abstract class ChatRepository {
  /// Inicia uma nova conversa pra [nutrizId] — o backend encerra
  /// automaticamente qualquer conversa aberta anterior dela.
  Future<int> iniciarConversa(int nutrizId);

  /// Manda [texto] na conversa [conversaId] e recebe de volta a mensagem da
  /// nutriz (já persistida) e a resposta da Lila, na mesma chamada. Hoje a
  /// resposta é um texto fixo (sem IA integrada ainda no backend) — o
  /// contrato não muda quando isso evoluir.
  Future<EnvioMensagemResultado> enviarMensagem({
    required int conversaId,
    required String texto,
  });
}
