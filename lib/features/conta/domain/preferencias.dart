/// Preferências da nutriz (`GET /preferencias-usuario/:id`).
///
/// O backend também tem um campo `tema`, mas o app ainda não implementa
/// tema escuro — expor esse controle na UI seria mostrar uma opção que não
/// faz nada, então ele fica de fora daqui até existir um tema escuro real.
class Preferencias {
  const Preferencias({
    required this.id,
    required this.notificacoesAtivas,
    required this.idioma,
  });

  final int id;
  final bool notificacoesAtivas;
  final String idioma;
}
