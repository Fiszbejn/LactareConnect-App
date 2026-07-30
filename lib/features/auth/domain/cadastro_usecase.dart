import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cadastro_repository_impl.dart';
import 'cadastro_repository.dart';
import 'cadastro_request.dart';
import 'login_usecase.dart';

/// Cria a conta e, se der certo, já loga com o e-mail/senha recém-criados
/// (reaproveitando o [LoginUseCase]) — evita pedir pra doadora digitar as
/// credenciais de novo logo depois de tê-las acabado de definir.
class CadastroUseCase {
  CadastroUseCase(this._repository, this._loginUseCase);

  final CadastroRepository _repository;
  final LoginUseCase _loginUseCase;

  Future<void> call(CadastroRequest request) async {
    await _repository.register(request);
    await _loginUseCase.call(email: request.email, senha: request.senha);
  }
}

final cadastroUseCaseProvider = Provider<CadastroUseCase>((ref) {
  return CadastroUseCase(
    ref.watch(cadastroRepositoryProvider),
    ref.watch(loginUseCaseProvider),
  );
});
