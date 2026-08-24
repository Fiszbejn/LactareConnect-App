class Doacao {
  const Doacao({
    required this.id,
    required this.volumeMl,
    required this.dataColeta,
    required this.agendamentoId,
  });

  final int id;
  final int volumeMl;
  final DateTime dataColeta;
  final int? agendamentoId;
}
