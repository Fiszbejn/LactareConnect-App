import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/agendamento.dart';
import '../domain/regiao_atendimento.dart';
import '../domain/doacao_failure.dart';
import 'doacao_controller.dart';

/// Histórico de agendamentos — sem wireframe (gap conhecido, mesmo caso já
/// documentado em "Meus resgates"). É aqui que o ciclo "agendei → a
/// coleta aconteceu → recebi gotinhas" se fecha: sem painel admin no
/// escopo deste app, decisão consultada com o usuário foi deixar a
/// própria nutriz confirmar e registrar (ver RegistrarDoacaoController).
class MeusAgendamentosScreen extends ConsumerWidget {
  const MeusAgendamentosScreen({super.key});

  static const routePath = 'meus-agendamentos';

  Future<void> _registrarDoacao(BuildContext context, WidgetRef ref, Agendamento agendamento) async {
    final volumeController = TextEditingController();
    final volumeMl = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar doação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quantos ml você coletou nessa doação?'),
            const SizedBox(height: 12),
            TextField(
              controller: volumeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Ex: 200', suffixText: 'ml'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(int.tryParse(volumeController.text)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (volumeMl == null || volumeMl <= 0 || !context.mounted) return;

    final sucesso = await ref.read(registrarDoacaoControllerProvider.notifier).confirmarEregistrar(
      agendamentoId: agendamento.id,
      volumeMl: volumeMl,
      dataColeta: agendamento.dataColeta,
    );
    if (!context.mounted) return;
    if (sucesso) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Doação registrada! Gotinhas creditadas.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendamentosAsync = ref.watch(meusAgendamentosProvider);
    final regioesAsync = ref.watch(regioesAtendimentoProvider);
    final registrando = ref.watch(registrarDoacaoControllerProvider).isLoading;

    ref.listen(registrarDoacaoControllerProvider, (previous, next) {
      final error = next.error;
      if (next is AsyncError && error is DoacaoFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Meus agendamentos')),
      body: agendamentosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Não foi possível carregar seus agendamentos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(meusAgendamentosProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (agendamentos) {
          if (agendamentos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Você ainda não tem nenhuma coleta agendada.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ),
            );
          }

          final regioes = <int, RegiaoAtendimento>{
            for (final r in regioesAsync.value ?? const <RegiaoAtendimento>[]) r.id: r,
          };

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: agendamentos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final agendamento = agendamentos[index];
              return _AgendamentoCard(
                agendamento: agendamento,
                regiao: regioes[agendamento.regiaoAtendimentoId],
                registrando: registrando,
                doacaoRegistrada: agendamento.doacaoId != null,
                onRegistrarDoacao: () => _registrarDoacao(context, ref, agendamento),
              );
            },
          );
        },
      ),
    );
  }
}

class _AgendamentoCard extends StatelessWidget {
  const _AgendamentoCard({
    required this.agendamento,
    required this.regiao,
    required this.registrando,
    required this.doacaoRegistrada,
    required this.onRegistrarDoacao,
  });

  final Agendamento agendamento;
  final RegiaoAtendimento? regiao;
  final bool registrando;
  final bool doacaoRegistrada;
  final VoidCallback onRegistrarDoacao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = _statusVisual(agendamento.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.brandTint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      regiao?.nome ?? 'Região #${agendamento.regiaoAtendimentoId ?? '?'}',
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat("d 'de' MMMM", 'pt_BR').format(agendamento.dataColeta)} · ${agendamento.horario}',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
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
          if (!doacaoRegistrada &&
              (agendamento.status == AgendamentoStatus.agendado ||
                  agendamento.status == AgendamentoStatus.realizado)) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: registrando ? null : onRegistrarDoacao,
                child: const Text('Confirmar coleta e registrar doação'),
              ),
            ),
          ],
          if (doacaoRegistrada) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppColors.statusOkText),
                const SizedBox(width: 6),
                Text(
                  'Doação registrada — gotinhas creditadas',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.statusOkText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
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

_StatusVisual _statusVisual(AgendamentoStatus status) => switch (status) {
  AgendamentoStatus.agendado => const _StatusVisual(
    label: 'Agendado',
    text: AppColors.statusPendingText,
    bg: AppColors.statusPendingBg,
  ),
  AgendamentoStatus.realizado => const _StatusVisual(
    label: 'Realizado',
    text: AppColors.statusOkText,
    bg: AppColors.statusOkBg,
  ),
  AgendamentoStatus.cancelado => const _StatusVisual(
    label: 'Cancelado',
    text: AppColors.statusErrorText,
    bg: AppColors.statusErrorBg,
  ),
};
