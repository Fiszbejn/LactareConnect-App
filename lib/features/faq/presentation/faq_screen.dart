import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/pergunta_frequente.dart';
import 'faq_controller.dart';

/// Tela de FAQ — é o conteúdo da aba "Início" (`screens-faq.jsx` usa
/// `tab={0}` no design; ver checkpoint de status pra esse achado). Híbrido
/// combinando as duas variantes do wireframe a pedido do usuário: banner
/// com gradiente + badges numerados em círculo com seta (da variante lista
/// simples) mantendo busca, categorias e accordion (da variante categorizada).
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoria;
  int? _expandedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _enviarFeedback(int perguntaId, bool util) async {
    try {
      await ref
          .read(faqFeedbackControllerProvider.notifier)
          .enviar(perguntaId: perguntaId, util: util);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível registrar seu feedback. Tente novamente.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final perguntasAsync = ref.watch(perguntasFrequentesProvider);
    final perguntasRespondidas = ref.watch(faqFeedbackControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perguntas frequentes', style: textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Tudo o que você quer saber, com carinho.',
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _FaqBanner(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar uma pergunta…',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(
              child: perguntasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ErroCarregarFaq(
                  onRetry: () => ref.invalidate(perguntasFrequentesProvider),
                ),
                data: (perguntas) => _FaqContent(
                  perguntas: perguntas,
                  searchQuery: _searchQuery,
                  selectedCategoria: _selectedCategoria,
                  onSelectCategoria: (categoria) =>
                      setState(() => _selectedCategoria = categoria),
                  expandedId: _expandedId,
                  onToggleExpand: (id) => setState(
                    () => _expandedId = _expandedId == id ? null : id,
                  ),
                  perguntasRespondidas: perguntasRespondidas,
                  onFeedback: _enviarFeedback,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroCarregarFaq extends StatelessWidget {
  const _ErroCarregarFaq({required this.onRetry});

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
              'Não foi possível carregar as perguntas frequentes.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _FaqBanner extends StatelessWidget {
  const _FaqBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você está bem informada,\nvocê doa melhor.',
            style: textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reunimos as perguntas mais comuns das doadoras.',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqContent extends StatelessWidget {
  const _FaqContent({
    required this.perguntas,
    required this.searchQuery,
    required this.selectedCategoria,
    required this.onSelectCategoria,
    required this.expandedId,
    required this.onToggleExpand,
    required this.perguntasRespondidas,
    required this.onFeedback,
  });

  final List<PerguntaFrequente> perguntas;
  final String searchQuery;
  final String? selectedCategoria;
  final ValueChanged<String?> onSelectCategoria;
  final int? expandedId;
  final ValueChanged<int> onToggleExpand;
  final Set<int> perguntasRespondidas;
  final void Function(int perguntaId, bool util) onFeedback;

  @override
  Widget build(BuildContext context) {
    final categorias = <String>[];
    final contagemPorCategoria = <String, int>{};
    for (final pergunta in perguntas) {
      contagemPorCategoria.update(
        pergunta.categoria,
        (valor) => valor + 1,
        ifAbsent: () => 1,
      );
      if (!categorias.contains(pergunta.categoria)) {
        categorias.add(pergunta.categoria);
      }
    }

    final query = searchQuery.trim().toLowerCase();
    final filtradas = perguntas.where((pergunta) {
      final categoriaOk =
          selectedCategoria == null || pergunta.categoria == selectedCategoria;
      final buscaOk = query.isEmpty || pergunta.pergunta.toLowerCase().contains(query);
      return categoriaOk && buscaOk;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoriaChip(
                  label: 'Todas',
                  count: perguntas.length,
                  selected: selectedCategoria == null,
                  color: AppColors.brand,
                  onTap: () => onSelectCategoria(null),
                );
              }
              final categoria = categorias[index - 1];
              return _CategoriaChip(
                label: _formatarCategoria(categoria),
                count: contagemPorCategoria[categoria] ?? 0,
                selected: selectedCategoria == categoria,
                color: AppColors
                    .categoryAccents[(index - 1) % AppColors.categoryAccents.length],
                onTap: () => onSelectCategoria(categoria),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (filtradas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhuma pergunta encontrada.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < filtradas.length; i++)
                _FaqAccordionItem(
                  indice: i + 1,
                  pergunta: filtradas[i],
                  expandido: expandedId == filtradas[i].id,
                  jaRespondida: perguntasRespondidas.contains(filtradas[i].id),
                  isUltimo: i == filtradas.length - 1,
                  onTap: () => onToggleExpand(filtradas[i].id),
                  onFeedback: (util) => onFeedback(filtradas[i].id, util),
                ),
            ],
          ),
        const SizedBox(height: 18),
        _FaqChatCta(
          onTap: () =>
              StatefulNavigationShell.of(context).goBranch(AppRoutes.chatBranchIndex),
        ),
      ],
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

class _CategoriaChip extends StatelessWidget {
  const _CategoriaChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : AppColors.line, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.lineSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqAccordionItem extends StatelessWidget {
  const _FaqAccordionItem({
    required this.indice,
    required this.pergunta,
    required this.expandido,
    required this.jaRespondida,
    required this.isUltimo,
    required this.onTap,
    required this.onFeedback,
  });

  final int indice;
  final PerguntaFrequente pergunta;
  final bool expandido;
  final bool jaRespondida;
  final bool isUltimo;
  final VoidCallback onTap;
  final ValueChanged<bool> onFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: expandido ? AppColors.brandTint : Colors.transparent,
          borderRadius: expandido ? BorderRadius.circular(12) : null,
          border: !expandido && !isUltimo
              ? const Border(bottom: BorderSide(color: AppColors.lineSoft))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.brandTint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$indice',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pergunta.pergunta,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: expandido ? FontWeight.w700 : FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: expandido ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: expandido ? AppColors.brand : AppColors.faint,
                  ),
                ),
              ],
            ),
            if (expandido) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pergunta.resposta,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (jaRespondida)
                      Text(
                        'Obrigada pelo feedback!',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Foi útil?',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            padding: const EdgeInsets.only(left: 8),
                            constraints: const BoxConstraints(),
                            onPressed: () => onFeedback(true),
                            icon: const Icon(Icons.thumb_up_outlined),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            padding: const EdgeInsets.only(left: 8),
                            constraints: const BoxConstraints(),
                            onPressed: () => onFeedback(false),
                            icon: const Icon(Icons.thumb_down_outlined),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqChatCta extends StatelessWidget {
  const _FaqChatCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandLight, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Não achou sua dúvida?',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Converse com nossa assistente Lila.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Abrir chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
