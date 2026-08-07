/// Mensagem pronta pra exibir — usada pelos 3 fluxos de escrita da
/// feature (enviar exame, agendar coleta, registrar doação).
class DoacaoFailure implements Exception {
  const DoacaoFailure(this.message);

  final String message;
}
