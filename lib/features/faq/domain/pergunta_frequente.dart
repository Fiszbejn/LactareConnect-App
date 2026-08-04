/// Uma pergunta frequente (`GET /perguntas-frequentes`) — entidade de
/// catálogo (leitura aberta a qualquer autenticado, escrita só admin),
/// sem regra de negócio do lado do cliente.
class PerguntaFrequente {
  const PerguntaFrequente({
    required this.id,
    required this.categoria,
    required this.pergunta,
    required this.resposta,
    required this.ordem,
  });

  final int id;
  final String categoria;
  final String pergunta;
  final String resposta;
  final int ordem;
}
