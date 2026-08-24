import 'pergunta_frequente.dart';

/// Contrato de acesso ao FAQ — a implementação real (Dio) fica em `data/`.
abstract class FaqRepository {
  Future<List<PerguntaFrequente>> getPerguntas();

  /// Registra se a pergunta [perguntaId] foi útil ([util]) para a nutriz
  /// [nutrizId] (`POST /feedbacks-faq`, recurso "dono-do-registro" — o
  /// backend rejeita com 403 se `nutrizId` não bater com o token).
  Future<void> enviarFeedback({
    required int perguntaId,
    required bool util,
    required int nutrizId,
  });
}
