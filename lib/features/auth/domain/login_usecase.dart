import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/auth_repository_impl.dart';
import 'auth_repository.dart';

/// Orquestra o login: chama o repository e, só se der certo, avisa o
/// [SessionController] — é o único lugar fora do `core/session` que
/// conhece os dois ao mesmo tempo.
class LoginUseCase {
  LoginUseCase(this._repository, this._sessionController);

  final AuthRepository _repository;
  final SessionController _sessionController;

  Future<void> call({required String email, required String senha}) async {
    final result = await _repository.login(email: email, senha: senha);
    await _sessionController.logIn(token: result.token, tipo: result.tipo);
  }
}

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionControllerProvider.notifier),
  );
});
