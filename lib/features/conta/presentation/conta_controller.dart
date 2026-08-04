import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../data/conta_repository_impl.dart';
import '../domain/endereco.dart';
import '../domain/nutriz_perfil.dart';
import '../domain/preferencias.dart';

/// Agrega as 3 entidades "dono-do-registro" que formam a tela de Conta —
/// carregadas juntas porque a tela sempre precisa das 3 ao mesmo tempo.
///
/// [endereco] é nulo quando a nutriz ainda não tem endereço cadastrado —
/// no fluxo normal (wizard de cadastro) isso não acontece, mas é um
/// estado válido pra contas criadas fora desse fluxo.
class ContaData {
  const ContaData({required this.perfil, required this.endereco, required this.preferencias});

  final NutrizPerfil perfil;
  final Endereco? endereco;
  final Preferencias preferencias;
}

final contaProvider = FutureProvider<ContaData>((ref) async {
  final nutrizId = ref.watch(sessionControllerProvider).nutrizId;
  if (nutrizId == null) {
    throw StateError('Sessão sem nutrizId — a tela de Conta exige login.');
  }

  final repository = ref.watch(contaRepositoryProvider);
  final perfil = await repository.getPerfil(nutrizId);
  final resultados = await Future.wait([
    perfil.enderecoId != null
        ? repository.getEndereco(perfil.enderecoId!)
        : Future.value(null),
    repository.getPreferencias(perfil.preferenciasId!),
  ]);

  return ContaData(
    perfil: perfil,
    endereco: resultados[0] as Endereco?,
    preferencias: resultados[1] as Preferencias,
  );
});

/// Ações de edição da conta — depois de cada uma, invalida [contaProvider]
/// pra buscar os dados atualizados de novo (mais simples e sem risco de
/// desalinhar cache local vs. servidor do que atualizar o estado na mão).
class ContaActionsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> _executar(Future<void> Function() acao) async {
    state = const AsyncLoading();
    final resultado = await AsyncValue.guard(acao);
    state = resultado;
    if (resultado.hasError) return false;
    ref.invalidate(contaProvider);
    return true;
  }

  Future<bool> atualizarPerfil({String? nome, String? telefone, String? email}) {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    return _executar(
      () => ref
          .read(contaRepositoryProvider)
          .atualizarPerfil(nutrizId: nutrizId, nome: nome, telefone: telefone, email: email),
    );
  }

  Future<bool> alterarSenha(String novaSenha) {
    final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
    return _executar(
      () => ref.read(contaRepositoryProvider).atualizarPerfil(
            nutrizId: nutrizId,
            senha: novaSenha,
          ),
    );
  }

  Future<bool> atualizarEndereco({
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    required String cidade,
    required String uf,
  }) {
    final enderecoAtual = ref.read(contaProvider).value!.endereco;
    final repository = ref.read(contaRepositoryProvider);

    if (enderecoAtual == null) {
      final nutrizId = ref.read(sessionControllerProvider).nutrizId!;
      return _executar(
        () => repository.criarEndereco(
          nutrizId: nutrizId,
          cep: cep,
          rua: rua,
          numero: numero,
          bairro: bairro,
          cidade: cidade,
          uf: uf,
        ),
      );
    }

    return _executar(
      () => repository.atualizarEndereco(
        enderecoId: enderecoAtual.id,
        cep: cep,
        rua: rua,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        uf: uf,
      ),
    );
  }

  Future<bool> atualizarNotificacoes(bool ativo) {
    final preferenciasId = ref.read(contaProvider).value!.preferencias.id;
    return _executar(
      () => ref
          .read(contaRepositoryProvider)
          .atualizarNotificacoes(preferenciasId: preferenciasId, notificacoesAtivas: ativo),
    );
  }
}

final contaActionsControllerProvider =
    NotifierProvider<ContaActionsController, AsyncValue<void>>(ContaActionsController.new);
