/// Mensagem pronta pra exibir — usada pelos 2 fluxos de escrita da feature
/// (iniciar conversa, enviar mensagem).
class ChatFailure implements Exception {
  const ChatFailure(this.message);

  final String message;
}
