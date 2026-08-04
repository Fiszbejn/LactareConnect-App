import 'endereco.dart';
import 'nutriz_perfil.dart';
import 'preferencias.dart';

/// Contrato de acesso aos dados de conta — a implementação real (Dio) fica
/// em `data/`. Junta 3 entidades "dono-do-registro" (Nutriz, Endereco,
/// PreferenciasUsuario) que juntas formam a tela de Conta.
abstract class ContaRepository {
  Future<NutrizPerfil> getPerfil(int nutrizId);
  Future<Endereco> getEndereco(int enderecoId);
  Future<Preferencias> getPreferencias(int preferenciasId);

  Future<void> atualizarPerfil({
    required int nutrizId,
    String? nome,
    String? telefone,
    String? email,
    String? senha,
  });

  Future<void> atualizarEndereco({
    required int enderecoId,
    required String cep,
    required String rua,
    required String numero,
    required String bairro,
    required String cidade,
    required String uf,
  });

  Future<void> atualizarNotificacoes({
    required int preferenciasId,
    required bool notificacoesAtivas,
  });
}
