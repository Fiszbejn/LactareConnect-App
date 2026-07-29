import 'cadastro_request.dart';

abstract class CadastroRepository {
  /// Cria a Nutriz e o Endereço vinculado. Não retorna nada porque quem
  /// chama (usecase) só precisa saber se deu certo — o login em seguida
  /// é feito com o e-mail/senha que a própria doadora acabou de definir.
  Future<void> register(CadastroRequest request);
}
