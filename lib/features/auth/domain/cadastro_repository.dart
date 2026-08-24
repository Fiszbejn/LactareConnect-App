import 'cadastro_request.dart';

abstract class CadastroRepository {
  /// Cria a Nutriz. É a única chamada de cadastro que não exige token
  /// (rota pública no backend) — retorna o `id` gerado, usado depois
  /// pra vincular o endereço.
  Future<int> registerNutriz(CadastroRequest request);

  /// Cria o Endereço vinculado à Nutriz. Ao contrário de `/nutrizes`,
  /// essa rota exige `Authorization: Bearer <token>` — por isso só pode
  /// ser chamada depois do login automático pós-cadastro (ver
  /// [CadastroUseCase]), nunca antes.
  Future<void> registerEndereco(int nutrizId, CadastroRequest request);
}
