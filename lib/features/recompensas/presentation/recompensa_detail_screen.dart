import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/recompensa.dart';
import '../domain/resgate_failure.dart';
import 'recompensas_controller.dart';

/// Confirmação de resgate — variante fiel ao wireframe `ScreenRewardDetail`,
/// com um ajuste de escopo (grounded no backend real, não perguntado ao
/// usuário, mesmo critério de FAQ/Conta): removido o bloco "O que vem na
/// cesta" — o backend não tem campo de descrição/conteúdo pra recompensa,
/// só nome/parceiro/categoria/custo/estoque — substituído por uma linha
/// real de disponibilidade. Endereço de entrega é sempre opcional aqui (o
/// backend aceita `enderecoEntrega` livre em qualquer resgate, não só nos
/// de categoria "produto"), pré-preenchido com o endereço cadastrado da
/// nutriz quando existir.
class RecompensaDetailScreen extends ConsumerStatefulWidget {
  const RecompensaDetailScreen({required this.recompensaId, super.key});

  static const routePath = ':id';

  final int recompensaId;

  @override
  ConsumerState<RecompensaDetailScreen> createState() => _RecompensaDetailScreenState();
}

class _RecompensaDetailScreenState extends ConsumerState<RecompensaDetailScreen> {
  final _enderecoController = TextEditingController();
  bool _enderecoPreenchido = false;

  @override
  void dispose() {
    _enderecoController.dispose();
    super.dispose();
  }

  Recompensa? _buscarRecompensa(List<Recompensa> lista) {
    for (final recompensa in lista) {
      if (recompensa.id == widget.recompensaId) return recompensa;
    }
    return null;
  }

  Future<void> _confirmarResgate(Recompensa recompensa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar resgate'),
        content: Text(
          'Você vai trocar ${recompensa.custoGotinhas} gotinhas por "${recompensa.nome}". '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final enderecoDigitado = _enderecoController.text.trim();
    final sucesso = await ref.read(resgateControllerProvider.notifier).resgatar(
          recompensaId: recompensa.id,
          enderecoEntrega: enderecoDigitado.isEmpty ? null : enderecoDigitado,
        );

    if (!mounted) return;
    if (sucesso) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Resgate confirmado!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dadosAsync = ref.watch(recompensasProvider);
    final resgatando = ref.watch(resgateControllerProvider).isLoading;

    ref.listen(resgateControllerProvider, (previous, next) {
      final error = next.error;
      if (next is AsyncError && error is ResgateFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Resgate')),
      body: dadosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Não foi possível carregar os dados do resgate.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ),
        data: (dados) {
          final recompensa = _buscarRecompensa(dados.recompensas);
          if (recompensa == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Essa recompensa não está mais disponível.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ),
            );
          }
          if (!_enderecoPreenchido) {
            _enderecoController.text = dados.enderecoResumo ?? '';
            _enderecoPreenchido = true;
          }

          final saldoSuficiente = dados.saldoGotinhas >= recompensa.custoGotinhas;
          final podeResgatar = recompensa.disponivel && saldoSuficiente && !resgatando;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.brand, AppColors.brandLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.card_giftcard,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recompensa.parceiro,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(recompensa.nome, style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.water_drop, size: 14, color: AppColors.brand),
                              const SizedBox(width: 4),
                              Text(
                                '${recompensa.custoGotinhas}',
                                style: const TextStyle(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Você tem ${dados.saldoGotinhas} gotinhas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            recompensa.disponivel ? Icons.inventory_2_outlined : Icons.error_outline,
                            size: 18,
                            color: recompensa.disponivel ? AppColors.statusOkText : AppColors.statusErrorText,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            recompensa.disponivel
                                ? recompensa.estoque == 1
                                      ? '1 unidade disponível'
                                      : '${recompensa.estoque} unidades disponíveis'
                                : 'Sem estoque no momento',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Endereço de entrega (opcional)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deixe em branco se essa recompensa não precisar de entrega.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _enderecoController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Rua, número · bairro · cidade/UF'),
                    ),
                    if (!saldoSuficiente) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusErrorBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Saldo insuficiente pra esse resgate.',
                          style: TextStyle(color: AppColors.statusErrorText, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.lineSoft)),
                ),
                child: FilledButton(
                  onPressed: podeResgatar ? () => _confirmarResgate(recompensa) : null,
                  child: resgatando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text('Resgatar agora — ${recompensa.custoGotinhas} gotinhas'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
