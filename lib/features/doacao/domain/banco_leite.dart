/// Banco de leite Lactare — só coleta domiciliar, o endereço é o do banco
/// que coordena a coleta, não um lugar que a nutriz visita.
class BancoLeite {
  const BancoLeite({
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

  /// Nulos quando o banco não tem coordenadas cadastradas — nesse caso o
  /// banco aparece na lista mas não no mapa nem na ordenação por distância.
  final double? latitude;
  final double? longitude;

  bool get temCoordenadas => latitude != null && longitude != null;
}
