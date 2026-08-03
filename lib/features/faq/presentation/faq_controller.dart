import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/faq_repository_impl.dart';
import '../domain/pergunta_frequente.dart';

/// `PerguntaFrequente` é uma entidade de catálogo (sem regra de negócio do
/// lado do cliente), então o provider chama o repositório direto — sem
/// usecase, seguindo o padrão já adotado no projeto (ver ADR de arquitetura).
final perguntasFrequentesProvider = FutureProvider<List<PerguntaFrequente>>((
  ref,
) {
  return ref.watch(faqRepositoryProvider).getPerguntas();
});

/// Guarda quais perguntas já receberam feedback nesta sessão de tela — só
/// pra trocar os botões "Foi útil?" por uma confirmação depois do toque
/// (o backend não impede votos duplicados, mas repetir não faz sentido pra
/// doadora).
class FaqFeedbackController extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  Future<void> enviar({required int perguntaId, required bool util}) async {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId;
    if (nutrizId == null) return;

    await ref
        .read(faqRepositoryProvider)
        .enviarFeedback(perguntaId: perguntaId, util: util, nutrizId: nutrizId);
    state = {...state, perguntaId};
  }
}

final faqFeedbackControllerProvider =
    NotifierProvider<FaqFeedbackController, Set<int>>(FaqFeedbackController.new);
