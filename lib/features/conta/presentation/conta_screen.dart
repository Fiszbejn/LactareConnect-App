import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/nutriz_perfil.dart';
import 'conta_controller.dart';

const _mesesPtBr = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Perfil da doadora — tela principal da aba "Conta". Variante confirmada
/// com o usuário: mescla da hero de perfil (estatísticas de impacto) com a
/// tela de configurações tabular (acessada daqui, ver [ConfiguracoesScreen]).
class ContaScreen extends ConsumerWidget {
  const ContaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contaAsync = ref.watch(contaProvider);

    return Scaffold(
      body: SafeArea(
        child: contaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErroCarregarConta(
            onRetry: () => ref.invalidate(contaProvider),
          ),
          data: (dados) => _ContaContent(dados: dados),
        ),
      ),
    );
  }
}

class _ErroCarregarConta extends StatelessWidget {
  const _ErroCarregarConta({required this.onRetry});

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
              'Não foi possível carregar seus dados.',
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

class _ContaContent extends ConsumerWidget {
  const _ContaContent({required this.dados});

  final ContaData dados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = dados.perfil;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Minha conta', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        _PerfilHero(dados: dados),
        const SizedBox(height: 20),
        _SecaoTitulo('Cadastro'),
        _CartaoLinhas(
          linhas: [
            _ContaRow(
              icon: Icons.badge_outlined,
              label: 'Dados pessoais',
              valor: '${perfil.nome} · CPF ${_formatarCpf(perfil.cpf)}',
              onTap: () => _abrirConfiguracoes(context),
            ),
            _ContaRow(
              icon: Icons.home_outlined,
              label: 'Contato e endereço',
              valor: perfil.telefone,
              onTap: () => _abrirConfiguracoes(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SecaoTitulo('Preferências'),
        _CartaoLinhas(
          linhas: [
            _ContaRow(
              icon: Icons.notifications_outlined,
              label: 'Notificações',
              valor: dados.preferencias.notificacoesAtivas ? 'Ativadas' : 'Desativadas',
              onTap: () => _abrirConfiguracoes(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SecaoTitulo('Privacidade'),
        _CartaoLinhas(
          linhas: [
            _ContaRow(
              icon: Icons.lock_outline,
              label: 'Segurança e senha',
              onTap: () => _abrirConfiguracoes(context),
            ),
            _ContaRow(
              icon: Icons.logout,
              label: 'Sair da conta',
              perigo: true,
              chevron: false,
              onTap: () => _confirmarLogout(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _abrirConfiguracoes(BuildContext context) {
    context.push(AppRoutes.contaConfiguracoes);
  }

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Você pode entrar de novo quando quiser continuar doando.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(sessionControllerProvider.notifier).logOut();
    }
  }
}

class _PerfilHero extends StatelessWidget {
  const _PerfilHero({required this.dados});

  final ContaData dados;

  @override
  Widget build(BuildContext context) {
    final perfil = dados.perfil;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.brandLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _iniciais(perfil.nome),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Doadora desde ${_mesesPtBr[perfil.dataCadastro.month - 1]} de ${perfil.dataCadastro.year}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroBadge(label: _statusLabel(perfil.status)),
                    _HeroBadge(label: '${perfil.saldoGotinhas} gotinhas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final primeira = partes.isNotEmpty ? partes.first[0] : '';
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }
}

String _statusLabel(NutrizStatus status) => switch (status) {
  NutrizStatus.aprovada => 'Cadastro aprovado',
  NutrizStatus.pendente => 'Cadastro em análise',
  NutrizStatus.inativa => 'Cadastro inativo',
};

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CartaoLinhas extends StatelessWidget {
  const _CartaoLinhas({required this.linhas});

  final List<_ContaRow> linhas;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: linhas),
    );
  }
}

class _ContaRow extends StatelessWidget {
  const _ContaRow({
    required this.icon,
    required this.label,
    this.valor,
    this.perigo = false,
    this.chevron = true,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? valor;
  final bool perigo;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final corIcone = perigo ? AppColors.statusErrorText : AppColors.brand;
    final corFundoIcone = perigo ? AppColors.statusErrorBg : AppColors.brandTint;
    final corTexto = perigo ? AppColors.statusErrorText : AppColors.ink;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: corFundoIcone,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: corIcone),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                  if (valor != null)
                    Text(
                      valor!,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            if (chevron)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

String _formatarCpf(String cpf) {
  if (cpf.length != 11) return cpf;
  return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
}
