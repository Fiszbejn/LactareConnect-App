/// Resultado de um login bem-sucedido (`POST /v1/auth/login`).
class LoginResult {
  const LoginResult({
    required this.token,
    required this.tipo,
    required this.id,
    required this.nome,
  });

  final String token;
  final String tipo;
  final int id;
  final String nome;
}
