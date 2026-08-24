import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/login_usecase.dart';

/// Estado assíncrono do botão "Entrar": `AsyncLoading` enquanto a
/// requisição está em voo, `AsyncError` com o [AuthFailure] se falhar.
/// Sucesso não guarda nada aqui — quem reage a login bem-sucedido é o
/// go_router, via `redirect` observando o `SessionController`.
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> login({required String email, required String senha}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginUseCaseProvider).call(email: email, senha: senha),
    );
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
