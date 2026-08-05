import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/recompensa.dart';
import '../domain/resgate.dart';
import 'recompensas_controller.dart';

/// Histórico de resgates da nutriz — gap conhecido do design (não existe
/// wireframe pra essa tela, só um botão "Meus resgates" sem destino no
/// catálogo), desenhada aqui seguindo o design system.
///
/// `ResgateResponseDto` só devolve `recompensaId` (sem nome/parceiro), então
/// cada item é cruzado com o catálogo já carregado em [recompensasProvider]
/// pra mostrar o nome — se a recompensa não estiver mais no catálogo
/// (removida), cai num rótulo genérico em vez de quebrar.
class MeusResgatesScreen extends ConsumerWidget {
  const MeusResgatesScreen({super.key});

  static const routePath = 'meus-resgates';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resgatesAsync = ref.watch(meusResgatesProvider);
    final catalogoAsync = ref.watch(recompensasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus resgates')),
      body: resgatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Não foi possível carregar seus resgates.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(meusResgatesProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (resgates) {
          if (resgates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Você ainda não resgatou nenhuma recompensa.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ),
            );
          }

          final catalogo = <int, Recompensa>{
            for (final recompensa in catalogoAsync.value?.recompensas ?? const <Recompensa>[])
              recompensa.id: recompensa,
          };

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: resgates.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final resgate = resgates[index];
              final recompensa = catalogo[resgate.recompensaId];
              return _ResgateCard(resgate: resgate, recompensa: recompensa);
            },
          );
        },
      ),
    );
  }
}

class _ResgateCard extends StatelessWidget {
  const _ResgateCard({required this.resgate, required this.recompensa});

  final Resgate resgate;
  final Recompensa? recompensa;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = _statusVisual(resgate.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.brandTint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.card_giftcard, size: 18, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recompensa?.nome ?? 'Recompensa #${resgate.recompensaId ?? '?'}',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(_formatarData(resgate.data), style: textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                if (resgate.enderecoEntrega != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    resgate.enderecoEntrega!,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: status.bg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              status.label,
              style: TextStyle(color: status.text, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusVisual {
  const _StatusVisual({required this.label, required this.text, required this.bg});

  final String label;
  final Color text;
  final Color bg;
}

_StatusVisual _statusVisual(ResgateStatus status) => switch (status) {
  ResgateStatus.pendente => const _StatusVisual(
    label: 'Pendente',
    text: AppColors.statusPendingText,
    bg: AppColors.statusPendingBg,
  ),
  ResgateStatus.enviado => const _StatusVisual(
    label: 'Enviado',
    text: AppColors.brand,
    bg: AppColors.brandTint,
  ),
  ResgateStatus.concluido => const _StatusVisual(
    label: 'Concluído',
    text: AppColors.statusOkText,
    bg: AppColors.statusOkBg,
  ),
};

String _formatarData(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';
}
