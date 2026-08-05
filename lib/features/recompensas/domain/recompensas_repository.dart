import 'nutriz_resumo.dart';
import 'recompensa.dart';
import 'resgate.dart';

/// Contrato de acesso aos dados de Recompensas — a implementação real
/// (Dio) fica em `data/`.
abstract class RecompensasRepository {
  Future<List<Recompensa>> getRecompensas();

  Future<NutrizResumo> getNutrizResumo(int nutrizId);

  /// Endereço formatado pra exibir/pré-preencher — só chamado quando
  /// [NutrizResumo.enderecoId] não é nulo.
  Future<String> getEnderecoResumo(int enderecoId);

  Future<List<Resgate>> getMeusResgates();

  /// Resgata [recompensaId] pra [nutrizId] — o backend debita gotinhas e
  /// estoque atomicamente (`POST /resgates`). Lança [ResgateFailure] com
  /// mensagem pronta se saldo/estoque/status não permitirem.
  Future<void> criarResgate({
    required int nutrizId,
    required int recompensaId,
    String? enderecoEntrega,
  });
}
