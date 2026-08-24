enum ResgateStatus { pendente, enviado, concluido }

ResgateStatus resgateStatusFromString(String value) {
  return ResgateStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ResgateStatus.pendente,
  );
}

/// Resgate de uma recompensa por gotinhas (`GET`/`POST /resgates`) —
/// "dono-do-registro": a nutriz só vê/cria os próprios.
///
/// [recompensaId] é a única referência à recompensa resgatada — o backend
/// não devolve nome/parceiro junto (`ResgateResponseDto` só tem o id),
/// então a tela "Meus resgates" precisa cruzar com o catálogo carregado
/// separadamente pra mostrar o nome.
class Resgate {
  const Resgate({
    required this.id,
    required this.status,
    required this.enderecoEntrega,
    required this.data,
    required this.recompensaId,
  });

  final int id;
  final ResgateStatus status;
  final String? enderecoEntrega;
  final DateTime data;
  final int? recompensaId;
}
