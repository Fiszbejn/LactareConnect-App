/// Erro de autenticação com mensagem já pronta para exibir na tela —
/// a camada de dados decide a tradução (401 vs erro de rede), a UI só mostra.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}
