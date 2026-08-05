/// Status do cadastro da nutriz (`Nutriz.status` no backend).
enum NutrizStatus { pendente, aprovada, inativa }

NutrizStatus nutrizStatusFromString(String value) {
  return NutrizStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => NutrizStatus.pendente,
  );
}

/// Dados de perfil da nutriz logada (`GET /nutrizes/:id`).
class NutrizPerfil {
  const NutrizPerfil({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.email,
    required this.status,
    required this.saldoGotinhas,
    required this.dataCadastro,
    required this.enderecoId,
    required this.preferenciasId,
  });

  final int id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final String telefone;
  final String email;
  final NutrizStatus status;
  final int saldoGotinhas;
  final DateTime dataCadastro;
  final int? enderecoId;
  final int? preferenciasId;
}
