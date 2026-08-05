/// Item do catálogo de "Gotinhas" (`GET /recompensas`) — recurso de
/// catálogo: leitura aberta a qualquer autenticado, escrita só admin.
class Recompensa {
  const Recompensa({
    required this.id,
    required this.nome,
    required this.parceiro,
    required this.categoria,
    required this.custoGotinhas,
    required this.estoque,
    required this.ativo,
    required this.imagemUrl,
  });

  final int id;
  final String nome;
  final String parceiro;
  final String categoria;
  final int custoGotinhas;
  final int estoque;
  final bool ativo;
  final String? imagemUrl;

  bool get disponivel => ativo && estoque > 0;
}
