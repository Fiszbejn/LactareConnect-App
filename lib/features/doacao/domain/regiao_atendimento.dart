/// Região de atendimento da Lactare — só coleta domiciliar, o endereço é o
/// da sede que coordena a coleta, não um lugar que a nutriz visita.
class RegiaoAtendimento {
  const RegiaoAtendimento({
    required this.id,
    required this.nome,
    required this.enderecoTexto,
    required this.areaAtendimento,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String nome;
  final String enderecoTexto;
  final String areaAtendimento;

  /// Nulos quando a região não tem coordenadas cadastradas — nesse caso ela
  /// aparece na lista mas não no mapa nem na ordenação por distância.
  final double? latitude;
  final double? longitude;

  bool get temCoordenadas => latitude != null && longitude != null;
}
