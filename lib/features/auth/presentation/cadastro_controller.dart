import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cadastro_request.dart';
import '../domain/cadastro_usecase.dart';

class CadastroController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> register(CadastroRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cadastroUseCaseProvider).call(request),
    );
  }
}

final cadastroControllerProvider =
    AsyncNotifierProvider<CadastroController, void>(CadastroController.new);
