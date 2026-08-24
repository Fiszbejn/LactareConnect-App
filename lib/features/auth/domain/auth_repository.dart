import 'login_result.dart';

/// Contrato de autenticação — a implementação real (Dio) fica em `data/`.
/// Este app é só da doadora, então `login` nunca expõe `tipo` pra UI:
/// quem implementa já sabe que é sempre `'nutriz'`.
abstract class AuthRepository {
  Future<LoginResult> login({required String email, required String senha});
}
