/// Endereço da nutriz (`GET /enderecos/:id`) — 1 por nutriz.
class Endereco {
  const Endereco({
    required this.id,
    required this.cep,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });

  final int id;
  final String cep;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;
}
