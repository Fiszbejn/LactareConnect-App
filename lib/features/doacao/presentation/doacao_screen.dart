import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/banco_leite.dart';
import 'doacao_controller.dart';
import 'location_provider.dart';

/// Centro do mapa quando ainda não há geolocalização nem banco com
/// coordenadas cadastradas — região dos bancos de exemplo do wireframe
/// original (São Paulo).
const _centroFallback = ll.LatLng(-23.5505, -46.6333);

const _urlRblh = 'https://rblh.fiocruz.br/localizacao-dos-blhs';

/// Tela "Doar" — mapa real (flutter_map + OpenStreetMap, sem API key) com
/// os bancos Lactare, ordenados por distância quando a nutriz permite
/// geolocalização. Ver domain/banco_leite.dart pra por que bancos sem
/// lat/long cadastrada aparecem só na lista, não no mapa.
class DoacaoScreen extends ConsumerStatefulWidget {
  const DoacaoScreen({super.key});

  @override
  ConsumerState<DoacaoScreen> createState() => _DoacaoScreenState();
}

class _DoacaoScreenState extends ConsumerState<DoacaoScreen> {
  final _mapController = MapController();
  int? _bancoSelecionadoId;

  @override
  Widget build(BuildContext context) {
    final bancosAsync = ref.watch(bancosProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final posicao = locationAsync.valueOrNull;

    // O mapa só recentraliza via `_mapController.move` — `initialCenter` do
    // FlutterMap é lido uma única vez, então se a geolocalização resolver
    // depois do primeiro frame (o normal, já que é assíncrona) o mapa fica
    // parado no centro de fallback pra sempre. Escutamos aqui pra mover o
    // mapa assim que uma posição nova aparecer, seja na resolução inicial
    // ou depois de um retoque no botão de recentralizar.
    ref.listen<AsyncValue<Position?>>(userLocationProvider, (anterior, atual) {
      final novaPosicao = atual.valueOrNull;
      if (novaPosicao != null && anterior?.valueOrNull == null) {
        _mapController.move(ll.LatLng(novaPosicao.latitude, novaPosicao.longitude), 14);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Doar'),
        actions: [
          IconButton(
            tooltip: 'Meus agendamentos',
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.doarMeusAgendamentos),
          ),
        ],
      ),
      body: bancosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErroCarregar(onRetry: () => ref.invalidate(bancosProvider)),
        data: (bancos) {
          final bancosOrdenados = _ordenarPorDistancia(bancos, posicao);
          // Espera a geolocalização resolver (concedida, negada ou com
          // erro) antes de travar a seleção inicial — senão o primeiro
          // build (sem posição ainda) seleciona o banco na ordem "crua"
          // do backend, sem levar a distância em conta.
          if (_bancoSelecionadoId == null && !locationAsync.isLoading && bancosOrdenados.isNotEmpty) {
            _bancoSelecionadoId = bancosOrdenados.first.id;
          }

          return Column(
            children: [
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    _Mapa(
                      mapController: _mapController,
                      bancos: bancos,
                      posicaoUsuario: posicao,
                      bancoSelecionadoId: _bancoSelecionadoId,
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _BotaoRecentralizar(
                        posicaoDisponivel: posicao != null,
                        tentandoLocalizar: locationAsync.isLoading,
                        onPressed: posicao != null
                            ? () => _mapController.move(ll.LatLng(posicao.latitude, posicao.longitude), 14)
                            : () => ref.invalidate(userLocationProvider),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: bancosOrdenados.isEmpty
                    ? const _SemBancos()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Bancos Lactare próximos', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.brandTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'COLETA EM CASA',
                                  style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recolhemos sua doação sem você sair de casa.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          for (final entry in bancosOrdenados.asMap().entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _BancoCard(
                                banco: entry.value,
                                posicaoUsuario: posicao,
                                selecionado: entry.value.id == _bancoSelecionadoId,
                                maisProximo: entry.key == 0 && posicao != null && entry.value.temCoordenadas,
                                onTap: () => setState(() => _bancoSelecionadoId = entry.value.id),
                              ),
                            ),
                          const SizedBox(height: 4),
                          const _LinkRblh(),
                        ],
                      ),
              ),
              if (_bancoSelecionadoId != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.lineSoft)),
                  ),
                  child: FilledButton(
                    onPressed: () => context.push(AppRoutes.doarAgendamento(_bancoSelecionadoId!)),
                    child: const Text('Agendar doação em casa'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<BancoLeite> _ordenarPorDistancia(List<BancoLeite> bancos, Position? posicao) {
    if (posicao == null) return bancos;
    final comCoordenadas = bancos.where((b) => b.temCoordenadas).toList()
      ..sort(
        (a, b) => _distanciaMetros(posicao, a).compareTo(_distanciaMetros(posicao, b)),
      );
    final semCoordenadas = bancos.where((b) => !b.temCoordenadas).toList();
    return [...comCoordenadas, ...semCoordenadas];
  }
}

double _distanciaMetros(Position posicao, BancoLeite banco) {
  return Geolocator.distanceBetween(
    posicao.latitude,
    posicao.longitude,
    banco.latitude!,
    banco.longitude!,
  );
}

class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.mapController,
    required this.bancos,
    required this.posicaoUsuario,
    required this.bancoSelecionadoId,
  });

  final MapController mapController;
  final List<BancoLeite> bancos;
  final Position? posicaoUsuario;
  final int? bancoSelecionadoId;

  ll.LatLng _centro() {
    if (posicaoUsuario != null) {
      return ll.LatLng(posicaoUsuario!.latitude, posicaoUsuario!.longitude);
    }
    for (final banco in bancos) {
      if (banco.temCoordenadas) return ll.LatLng(banco.latitude!, banco.longitude!);
    }
    return _centroFallback;
  }

  @override
  Widget build(BuildContext context) {
    final centro = _centro();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: centro, initialZoom: 13),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.lactareconnect',
        ),
        MarkerLayer(
          markers: [
            if (posicaoUsuario != null)
              Marker(
                point: ll.LatLng(posicaoUsuario!.latitude, posicaoUsuario!.longitude),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
            for (final banco in bancos.where((b) => b.temCoordenadas))
              Marker(
                point: ll.LatLng(banco.latitude!, banco.longitude!),
                width: 36,
                height: 36,
                child: Icon(
                  Icons.location_on,
                  size: 34,
                  color: banco.id == bancoSelecionadoId ? AppColors.brand : AppColors.brandLight,
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// Quando já há posição, recentraliza o mapa nela. Quando não há (GPS sem
/// fix, permissão negada, timeout — ver location_provider.dart), o toque
/// dispara uma nova tentativa em vez de ficar sem fazer nada: sem isso, o
/// botão travava desabilitado pra sempre depois da primeira falha, já que
/// o `userLocationProvider` (um `FutureProvider` comum) fica em cache e
/// nunca tenta de novo sozinho.
class _BotaoRecentralizar extends StatelessWidget {
  const _BotaoRecentralizar({
    required this.onPressed,
    required this.posicaoDisponivel,
    required this.tentandoLocalizar,
  });

  final VoidCallback onPressed;
  final bool posicaoDisponivel;
  final bool tentandoLocalizar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: tentandoLocalizar ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: tentandoLocalizar
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.faint),
                )
              : Icon(
                  Icons.my_location,
                  size: 18,
                  color: posicaoDisponivel ? AppColors.brand : AppColors.faint,
                ),
        ),
      ),
    );
  }
}

class _BancoCard extends StatelessWidget {
  const _BancoCard({
    required this.banco,
    required this.posicaoUsuario,
    required this.selecionado,
    required this.maisProximo,
    required this.onTap,
  });

  final BancoLeite banco;
  final Position? posicaoUsuario;
  final bool selecionado;
  final bool maisProximo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distanciaKm = (posicaoUsuario != null && banco.temCoordenadas)
        ? _distanciaMetros(posicaoUsuario!, banco) / 1000
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selecionado ? AppColors.brand : AppColors.line, width: selecionado ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selecionado ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selecionado ? AppColors.brand : AppColors.faint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          banco.nome,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (maisProximo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(7)),
                          child: const Text(
                            'MAIS PRÓXIMO',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 8.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    distanciaKm != null
                        ? '${distanciaKm.toStringAsFixed(1)} km · ${banco.areaAtendimento}'
                        : banco.areaAtendimento,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRblh extends StatelessWidget {
  const _LinkRblh();

  Future<void> _abrirRblh(BuildContext context) async {
    final aberto = await launchUrl(Uri.parse(_urlRblh), mode: LaunchMode.externalApplication);
    if (!aberto && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirRblh(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusPendingBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.statusPendingText.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.public, size: 18, color: AppColors.statusPendingText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Não estamos na sua cidade?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Veja todos os bancos de leite do Brasil no cadastro nacional da rBLH.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.statusPendingText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: AppColors.statusPendingText),
            ],
          ),
        ),
      ),
    );
  }
}

class _SemBancos extends StatelessWidget {
  const _SemBancos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nenhum banco Lactare disponível no momento.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _ErroCarregar extends StatelessWidget {
  const _ErroCarregar({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Não foi possível carregar os bancos de leite.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
