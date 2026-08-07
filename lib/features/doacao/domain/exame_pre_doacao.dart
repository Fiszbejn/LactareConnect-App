/// Só os 4 tipos que o backend de fato exige pra liberar um agendamento
/// (`AgendamentoService.EXAMES_OBRIGATORIOS`). O enum real do backend tem
/// mais 3 valores (`carteira_pre_natal`, `sorologias`, `htlv`) sem nenhuma
/// regra de negócio associada — o wireframe original mostrava justamente
/// esses 3 "extras" e omitia o vdrl real, então o checklist foi refeito
/// aqui em cima do contrato de verdade, não do mockup.
enum ExameTipo { hemograma, sorologiaHiv, vdrl, sorologiaHepatitesBC }

extension ExameTipoApi on ExameTipo {
  String get valorBackend => switch (this) {
    ExameTipo.hemograma => 'hemograma',
    ExameTipo.sorologiaHiv => 'sorologia_hiv',
    ExameTipo.vdrl => 'vdrl',
    ExameTipo.sorologiaHepatitesBC => 'sorologia_hepatites_b_c',
  };

  String get label => switch (this) {
    ExameTipo.hemograma => 'Hemograma completo',
    ExameTipo.sorologiaHiv => 'Sorologia HIV',
    ExameTipo.vdrl => 'VDRL (sífilis)',
    ExameTipo.sorologiaHepatitesBC => 'Sorologia hepatites B e C',
  };
}

/// `null` quando o valor não é um dos 4 tipos obrigatórios (linha antiga de
/// teste com outro tipo do enum do backend, por exemplo) — descartada pelo
/// repositório em vez de quebrar o checklist.
ExameTipo? exameTipoFromBackend(String valor) {
  for (final tipo in ExameTipo.values) {
    if (tipo.valorBackend == valor) return tipo;
  }
  return null;
}

enum ExameStatus { ok, pendente, faltando }

ExameStatus exameStatusFromBackend(String valor) => switch (valor) {
  'ok' => ExameStatus.ok,
  'pendente' => ExameStatus.pendente,
  _ => ExameStatus.faltando,
};

class ExamePreDoacao {
  const ExamePreDoacao({
    required this.id,
    required this.tipoExame,
    required this.status,
    required this.arquivoUrl,
    required this.dataEnvio,
  });

  final int id;
  final ExameTipo tipoExame;
  final ExameStatus status;
  final String? arquivoUrl;
  final DateTime? dataEnvio;
}
