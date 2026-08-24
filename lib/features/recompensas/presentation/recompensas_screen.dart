import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/recompensa.dart';
import 'recompensas_controller.dart';

/// Catálogo de recompensas — aba "Recompensas". Variante fiel ao
/// wireframe `screens-rewards.jsx`, com 2 ajustes de escopo consultados no
/// contrato real do backend (não perguntados ao usuário, mesmo critério
/// já usado em FAQ/Conta — reportado depois):
/// - Categorias são texto livre (`Recompensa.categoria` não é enum no
///   backend), então os chips são gerados dinamicamente a partir do
///   catálogo carregado, igual às categorias da FAQ.
/// - O bloco "Como ganhar gotinhas" do wireframe listava pontuação por
///   ação (exame +50, indicação +200, perfil +80) que não existe no
///   backend — só a doação credita gotinhas de fato (100 fixas por
///   doação, ver `doacao.service.ts`). O texto aqui reflete isso.
class RecompensasScreen extends ConsumerStatefulWidget {
  const RecompensasScreen({super.key});

  @override
  ConsumerState<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends ConsumerState<RecompensasScreen> {
  String? _categoriaSelecionada;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dadosAsync = ref.watch(recompensasProvider);

    return Scaffold(
      body: SafeArea(
        child: dadosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErroCarregarRecompensas(
            onRetry: () => ref.invalidate(recompensasProvider),
          ),
          data: (dados) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text('Recompensas', style: textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Troque suas gotinhas por cuidado pra você.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _SaldoHero(dados: dados),
              const SizedBox(height: 20),
              _CategoriaChips(
                recompensas: dados.recompensas,
                selecionada: _categoriaSelecionada,
                onSelect: (categoria) => setState(() => _categoriaSelecionada = categoria),
              ),
              const SizedBox(height: 14),
              _CatalogoGrid(
                recompensas: dados.recompensas
                    .where(
                      (r) => _categoriaSelecionada == null || r.categoria == _categoriaSelecionada,
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              const _ComoGanharCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErroCarregarRecompensas extends StatelessWidget {
  const _ErroCarregarRecompensas({required this.onRetry});

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
              'Não foi possível carregar as recompensas.',
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

class _SaldoHero extends StatelessWidget {
  const _SaldoHero({required this.dados});

  final RecompensasData dados;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandLight],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEU SALDO',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(
                dados.saldoGotinhas.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'gotinhas',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push(AppRoutes.meusResgates),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Meus resgates',
                    style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.brand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaChips extends StatelessWidget {
  const _CategoriaChips({
    required this.recompensas,
    required this.selecionada,
    required this.onSelect,
  });

  final List<Recompensa> recompensas;
  final String? selecionada;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final categorias = <String>[];
    for (final recompensa in recompensas) {
      if (!categorias.contains(recompensa.categoria)) {
        categorias.add(recompensa.categoria);
      }
    }

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(label: 'Todos', selected: selecionada == null, onTap: () => onSelect(null));
          }
          final categoria = categorias[index - 1];
          return _Chip(
            label: _formatarCategoria(categoria),
            selected: selecionada == categoria,
            onTap: () => onSelect(categoria),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

String _formatarCategoria(String categoria) {
  return categoria
      .replaceAll(RegExp('[_-]'), ' ')
      .split(' ')
      .where((palavra) => palavra.isNotEmpty)
      .map((palavra) => palavra[0].toUpperCase() + palavra.substring(1).toLowerCase())
      .join(' ');
}

class _CatalogoGrid extends StatelessWidget {
  const _CatalogoGrid({required this.recompensas});

  final List<Recompensa> recompensas;

  @override
  Widget build(BuildContext context) {
    if (recompensas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Nenhuma recompensa nessa categoria.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recompensas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => _RecompensaCard(recompensa: recompensas[index], indice: index),
    );
  }
}

class _RecompensaCard extends StatelessWidget {
  const _RecompensaCard({required this.recompensa, required this.indice});

  final Recompensa recompensa;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final cor = AppColors.categoryAccents[indice % AppColors.categoryAccents.length];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(AppRoutes.recompensaDetalhe(recompensa.id)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 78,
              width: double.infinity,
              color: cor,
              alignment: Alignment.center,
              child: recompensa.disponivel
                  ? Icon(Icons.card_giftcard, color: Colors.white.withValues(alpha: 0.9), size: 28)
                  : Text(
                      'ESGOTADO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recompensa.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recompensa.parceiro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CoinBadge(valor: recompensa.custoGotinhas),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: recompensa.disponivel ? AppColors.brand : AppColors.lineSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recompensa.disponivel ? 'Resgatar' : '—',
                          style: TextStyle(
                            color: recompensa.disponivel ? Colors.white : AppColors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.valor});

  final int valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.brandTint, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop, size: 11, color: AppColors.brand),
          const SizedBox(width: 3),
          Text(
            valor.toString(),
            style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ComoGanharCard extends StatelessWidget {
  const _ComoGanharCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como ganhar gotinhas', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 1),
                decoration: const BoxDecoration(color: AppColors.brandTint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.water_drop, size: 13, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cada doação registrada soma gotinhas no seu saldo automaticamente. '
                  'Outras formas de ganhar — como indicar uma amiga — estão a caminho.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
