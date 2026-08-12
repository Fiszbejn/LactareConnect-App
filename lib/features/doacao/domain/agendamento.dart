enum AgendamentoStatus { agendado, realizado, cancelado }

AgendamentoStatus agendamentoStatusFromBackend(String valor) => switch (valor) {
  'realizado' => AgendamentoStatus.realizado,
  'cancelado' => AgendamentoStatus.cancelado,
  _ => AgendamentoStatus.agendado,
};

class Agendamento {
  const Agendamento({
    required this.id,
    required this.dataColeta,
    required this.horario,
    required this.status,
    required this.regiaoAtendimentoId,
    required this.doacaoId,
  });

  final int id;
  final DateTime dataColeta;
  final String horario;
  final AgendamentoStatus status;
  final int? regiaoAtendimentoId;

  /// Preenchido só depois que a doação é registrada a partir deste
  /// agendamento — usado pra saber se o botão "Registrar doação" ainda
  /// deve aparecer ou se o ciclo já foi fechado.
  final int? doacaoId;
}
