import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/doacao_repository_impl.dart';
import '../domain/agendamento.dart';
import '../domain/banco_leite.dart';
import '../domain/exame_pre_doacao.dart';

final bancosProvider = FutureProvider<List<BancoLeite>>((ref) {
  return ref.watch(doacaoRepositoryProvider).getBancos();
});

final meusExamesProvider = FutureProvider<List<ExamePreDoacao>>((ref) {
  return ref.watch(doacaoRepositoryProvider).getMeusExames();
});

final meusAgendamentosProvider = FutureProvider<List<Agendamento>>((ref) {
  return ref.watch(doacaoRepositoryProvider).getMeusAgendamentos();
});

/// Envio do comprovante de um exame — não existe upload real no backend
/// (ver decisão registrada: `ExamePreDoacao.arquivoUrl` é só texto, sem
/// storage por trás). O arquivo escolhido no aparelho vira um
/// `arquivoUrl` fictício que só serve pra destravar o `status: ok`.
class ExameUploadController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> enviar({
    required ExameTipo tipo,
    required String arquivoUrl,
    int? exameIdExistente,
  }) async {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(doacaoRepositoryProvider).enviarExame(
        nutrizId: nutrizId,
        tipo: tipo,
        arquivoUrl: arquivoUrl,
        exameIdExistente: exameIdExistente,
      ),
    );
    if (state.hasError) return false;
    ref.invalidate(meusExamesProvider);
    return true;
  }
}

final exameUploadControllerProvider =
    AsyncNotifierProvider<ExameUploadController, void>(ExameUploadController.new);

class AgendamentoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> agendar({
    required int bancoId,
    required DateTime dataColeta,
    required String horario,
  }) async {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(doacaoRepositoryProvider).criarAgendamento(
        nutrizId: nutrizId,
        bancoId: bancoId,
        dataColeta: dataColeta,
        horario: horario,
      ),
    );
    if (state.hasError) return false;
    ref.invalidate(meusAgendamentosProvider);
    return true;
  }
}

final agendamentoControllerProvider =
    AsyncNotifierProvider<AgendamentoController, void>(AgendamentoController.new);

/// "Confirmar coleta realizada" + "registrar doação" — decisão consultada
/// com o usuário: sem painel admin no escopo deste app, é a própria
/// nutriz que fecha o ciclo. As duas chamadas em sequência porque o
/// backend só aceita `POST /doacoes` depois que o agendamento já está
/// `realizado`; a segunda credita as 100 gotinhas automaticamente.
class RegistrarDoacaoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> confirmarEregistrar({
    required int agendamentoId,
    required int volumeMl,
    required DateTime dataColeta,
  }) async {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(doacaoRepositoryProvider);
      await repository.confirmarColetaRealizada(agendamentoId);
      await repository.registrarDoacao(
        nutrizId: nutrizId,
        agendamentoId: agendamentoId,
        volumeMl: volumeMl,
        dataColeta: dataColeta,
      );
    });
    if (state.hasError) return false;
    ref.invalidate(meusAgendamentosProvider);
    return true;
  }
}

final registrarDoacaoControllerProvider =
    AsyncNotifierProvider<RegistrarDoacaoController, void>(RegistrarDoacaoController.new);
