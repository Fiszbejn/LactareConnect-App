import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Posição atual do dispositivo, pra centralizar o mapa e ordenar os
/// bancos por distância. `null` quando o serviço de localização está
/// desligado, a permissão foi negada, ou o aparelho demora demais pra
/// conseguir um fix de GPS (`timeLimit` abaixo) — a tela cai pro estado
/// sem geolocalização (lista na ordem que veio do backend, mapa num
/// ponto fixo) em vez de travar esperando pra sempre. Sem esse limite,
/// testado no emulador Android: sem um fix de GPS simulado,
/// `getCurrentPosition` nunca resolve e a tela de Doar fica sem CTA
/// pra sempre — o mesmo aconteceria com uma nutriz real num local sem
/// sinal de GPS (ex: dentro de casa).
///
/// Fluxo do `Geolocator` (biblioteca nova no projeto): primeiro checa se o
/// serviço de localização do aparelho está ligado; depois checa a
/// permissão do app e pede ao usuário se ainda não foi decidida; só então
/// dá pra ler a posição atual. É por isso que o provider é assíncrono
/// (`FutureProvider`) — cada uma dessas etapas pode esperar o usuário.
final userLocationProvider = FutureProvider<Position?>((ref) async {
  final servicoLigado = await Geolocator.isLocationServiceEnabled();
  if (!servicoLigado) return null;

  var permissao = await Geolocator.checkPermission();
  if (permissao == LocationPermission.denied) {
    permissao = await Geolocator.requestPermission();
  }
  if (permissao == LocationPermission.denied ||
      permissao == LocationPermission.deniedForever) {
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  } catch (_) {
    return null;
  }
});
