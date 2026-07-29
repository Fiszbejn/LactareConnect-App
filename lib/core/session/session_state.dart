enum SessionStatus { loading, authenticated, unauthenticated }

/// Estado de sessão do app: se há um usuário logado, com qual token e
/// qual `tipo` (`nutriz` | `administrador`, ver contrato do backend).
///
/// `loading` existe porque ler o token do secure storage é assíncrono —
/// no primeiro frame do app ainda não sabemos se há sessão ou não.
class SessionState {
  const SessionState._({required this.status, this.token, this.tipo});

  final SessionStatus status;
  final String? token;
  final String? tipo;

  static const loading = SessionState._(status: SessionStatus.loading);
  static const unauthenticated = SessionState._(
    status: SessionStatus.unauthenticated,
  );

  factory SessionState.authenticated({
    required String token,
    required String tipo,
  }) {
    return SessionState._(
      status: SessionStatus.authenticated,
      token: token,
      tipo: tipo,
    );
  }

  bool get isLoading => status == SessionStatus.loading;

  /// Este app é só da doadora — um admin autenticado (via seed) não deve
  /// ser tratado como sessão válida aqui, mesmo com token correto.
  bool get isAuthenticatedAsNutriz =>
      status == SessionStatus.authenticated && tipo == 'nutriz';
}
