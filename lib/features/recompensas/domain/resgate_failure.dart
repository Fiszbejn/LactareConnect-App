/// Erro ao resgatar uma recompensa, com mensagem já pronta pra exibir — a
/// camada de dados traduz o 400 do backend (saldo insuficiente, sem
/// estoque, recompensa inativa), a UI só mostra.
class ResgateFailure implements Exception {
  const ResgateFailure(this.message);

  final String message;
}
