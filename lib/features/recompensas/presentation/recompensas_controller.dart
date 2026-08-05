import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/recompensas_repository_impl.dart';
import '../domain/nutriz_resumo.dart';
import '../domain/recompensa.dart';
import '../domain/resgate.dart';

/// Agrega saldo + catálogo — a tela de Recompensas sempre precisa dos dois
/// juntos (mesmo padrão do `ContaData`, ver feature `conta`).
class RecompensasData {
  const RecompensasData({
    required this.saldoGotinhas,
    required this.recompensas,
    required this.enderecoResumo,
  });

  final int saldoGotinhas;
  final List<Recompensa> recompensas;

  /// Nulo se a nutriz ainda não tiver endereço cadastrado (mesmo caso
  /// opcional já tratado em Conta) — usado só pra pré-preencher o campo
  /// de entrega no resgate.
  final String? enderecoResumo;
}

final recompensasProvider = FutureProvider<RecompensasData>((ref) async {
  final nutrizId = ref.watch(sessionControllerProvider).nutrizId;
  if (nutrizId == null) {
    throw StateError('Sessão sem nutrizId — a tela de Recompensas exige login.');
  }

  final repository = ref.watch(recompensasRepositoryProvider);
  final resultados = await Future.wait([
    repository.getNutrizResumo(nutrizId),
    repository.getRecompensas(),
  ]);

  final resumo = resultados[0] as NutrizResumo;
  final recompensas = resultados[1] as List<Recompensa>;
  final enderecoResumo = resumo.enderecoId != null
      ? await repository.getEnderecoResumo(resumo.enderecoId!)
      : null;

  return RecompensasData(
    saldoGotinhas: resumo.saldoGotinhas,
    recompensas: recompensas,
    enderecoResumo: enderecoResumo,
  );
});

/// Resgates da nutriz logada — carregado só quando a tela "Meus resgates"
/// abre (não é necessário no catálogo principal).
final meusResgatesProvider = FutureProvider<List<Resgate>>((ref) {
  return ref.watch(recompensasRepositoryProvider).getMeusResgates();
});

/// Estado assíncrono do botão "Resgatar agora" — `AsyncError` com
/// [ResgateFailure] se falhar (ver domain/resgate_failure.dart). Sucesso
/// invalida [recompensasProvider] pra refletir o saldo/estoque novos.
class ResgateController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> resgatar({required int recompensaId, String? enderecoEntrega}) async {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recompensasRepositoryProvider).criarResgate(
            nutrizId: nutrizId,
            recompensaId: recompensaId,
            enderecoEntrega: enderecoEntrega,
          ),
    );
    if (state.hasError) return false;
    ref.invalidate(recompensasProvider);
    return true;
  }
}

final resgateControllerProvider = AsyncNotifierProvider<ResgateController, void>(
  ResgateController.new,
);
