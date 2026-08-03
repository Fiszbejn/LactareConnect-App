import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/token_storage.dart';
import 'session_state.dart';

/// Dono do estado de sessão. É o único lugar que escreve em [TokenStorage]
/// — o interceptor do Dio só lê, e só chama [logOut] quando o backend
/// retorna 401. O futuro usecase de login da feature `auth` vai chamar
/// [logIn] depois de bater em `POST /v1/auth/login` com sucesso.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    _restoreFromStorage();
    return SessionState.loading;
  }

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);

  Future<void> _restoreFromStorage() async {
    final token = await _tokenStorage.readToken();
    final tipo = await _tokenStorage.readTipo();
    final nutrizId = await _tokenStorage.readNutrizId();

    state = (token != null && tipo != null && nutrizId != null)
        ? SessionState.authenticated(token: token, tipo: tipo, nutrizId: nutrizId)
        : SessionState.unauthenticated;
  }

  Future<void> logIn({
    required String token,
    required String tipo,
    required int nutrizId,
  }) async {
    await _tokenStorage.saveSession(token: token, tipo: tipo, nutrizId: nutrizId);
    state = SessionState.authenticated(token: token, tipo: tipo, nutrizId: nutrizId);
  }

  Future<void> logOut() async {
    await _tokenStorage.clearSession();
    state = SessionState.unauthenticated;
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
