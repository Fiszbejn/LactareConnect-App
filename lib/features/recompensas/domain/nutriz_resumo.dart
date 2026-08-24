/// Recorte da nutriz relevante pra tela de Recompensas — saldo (hero de
/// saldo) e endereço (pra pré-preencher o campo de entrega do resgate, se
/// a nutriz já tiver um cadastrado — mesmo caso opcional já tratado em
/// Conta, nem toda conta passou pelo wizard completo).
class NutrizResumo {
  const NutrizResumo({required this.saldoGotinhas, required this.enderecoId});

  final int saldoGotinhas;
  final int? enderecoId;
}
