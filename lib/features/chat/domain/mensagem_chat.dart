enum RemetenteMensagem { usuario, bot }

RemetenteMensagem remetenteMensagemFromBackend(String valor) => switch (valor) {
  'bot' => RemetenteMensagem.bot,
  _ => RemetenteMensagem.usuario,
};

class MensagemChat {
  const MensagemChat({
    required this.id,
    required this.remetente,
    required this.texto,
    required this.timestamp,
  });

  final int id;
  final RemetenteMensagem remetente;
  final String texto;
  final DateTime timestamp;
}

/// Resultado de `POST /conversas/:id/mensagens` — a mensagem da nutriz já
/// persistida e a resposta da Lila, na mesma chamada (ver
/// domain/chat_repository.dart pra por que não tem GET de histórico aqui).
class EnvioMensagemResultado {
  const EnvioMensagemResultado({required this.mensagemUsuario, required this.respostaBot});

  final MensagemChat mensagemUsuario;
  final MensagemChat respostaBot;
}
