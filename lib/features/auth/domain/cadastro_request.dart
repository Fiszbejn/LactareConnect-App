/// Dados coletados nos 3 passos do wizard de cadastro, já normalizados
/// (dígitos limpos, data em ISO) — prontos pra virar o corpo das
/// requisições `POST /nutrizes` e `POST /enderecos`.
class CadastroRequest {
  const CadastroRequest({
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.email,
    required this.senha,
    required this.cep,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });

  final String nome;
  final String cpf;

  /// ISO 8601 (`yyyy-MM-dd`), formato exigido pelo `CreateNutrizDto`.
  final String dataNascimento;
  final String telefone;
  final String email;
  final String senha;
  final String cep;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;
}
