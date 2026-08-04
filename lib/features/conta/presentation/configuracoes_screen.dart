import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/endereco.dart';
import 'conta_controller.dart';

/// Configurações tabulares — acessada a partir da tela de Perfil
/// ([ContaScreen]). Variante confirmada com o usuário: mescla das duas
/// telas de conta do design (perfil + configurações), com edição de
/// verdade (não só exibição) pra cada campo que o backend suporta.
class ConfiguracoesScreen extends ConsumerWidget {
  const ConfiguracoesScreen({super.key});

  static const routePath = 'configuracoes';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contaAsync = ref.watch(contaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: contaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Não foi possível carregar seus dados.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ),
        data: (dados) => _ConfiguracoesContent(dados: dados),
      ),
    );
  }
}

class _ConfiguracoesContent extends ConsumerWidget {
  const _ConfiguracoesContent({required this.dados});

  final ContaData dados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = dados.perfil;
    final endereco = dados.endereco;
    final actions = ref.read(contaActionsControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _SecaoConfig(
          titulo: 'Dados pessoais',
          linhas: [
            _LinhaConfig(
              rotulo: 'Nome completo',
              valor: perfil.nome,
              onTap: () => _editarTexto(
                context,
                titulo: 'Nome completo',
                valorInicial: perfil.nome,
                onSalvar: (novoValor) => actions.atualizarPerfil(nome: novoValor),
              ),
            ),
            _LinhaConfig(rotulo: 'CPF', valor: _formatarCpf(perfil.cpf), editavel: false),
            _LinhaConfig(
              rotulo: 'Data de nascimento',
              valor: _formatarData(perfil.dataNascimento),
              editavel: false,
            ),
            _LinhaConfig(
              rotulo: 'Telefone',
              valor: perfil.telefone,
              onTap: () => _editarTexto(
                context,
                titulo: 'Telefone',
                valorInicial: perfil.telefone,
                teclado: TextInputType.phone,
                onSalvar: (novoValor) => actions.atualizarPerfil(telefone: novoValor),
              ),
            ),
            _LinhaConfig(
              rotulo: 'E-mail',
              valor: perfil.email,
              onTap: () => _editarTexto(
                context,
                titulo: 'E-mail',
                valorInicial: perfil.email,
                teclado: TextInputType.emailAddress,
                validador: (valor) =>
                    (!valor.contains('@') || !valor.contains('.'))
                        ? 'Informe um e-mail válido.'
                        : null,
                onSalvar: (novoValor) => actions.atualizarPerfil(email: novoValor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SecaoConfig(
          titulo: 'Endereço',
          linhas: [
            _LinhaConfig(
              rotulo: 'Endereço de coleta',
              valor: '${endereco.rua}, ${endereco.numero} · ${endereco.cidade}/${endereco.uf}',
              multilinha: true,
              onTap: () => _editarEndereco(context, ref, endereco: endereco, actions: actions),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SecaoConfig(
          titulo: 'Preferências',
          linhas: [
            _LinhaConfig(
              rotulo: 'Idioma',
              valor: 'Português (BR)',
              editavel: false,
            ),
          ],
          extra: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Notificações'),
            subtitle: const Text('Lembretes sobre a sua doação'),
            value: dados.preferencias.notificacoesAtivas,
            onChanged: (ativo) => actions.atualizarNotificacoes(ativo),
          ),
        ),
        const SizedBox(height: 18),
        _SecaoConfig(
          titulo: 'Segurança',
          linhas: [
            _LinhaConfig(
              rotulo: 'Alterar senha',
              onTap: () => _alterarSenha(context, actions),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SecaoConfig(
          titulo: 'Sobre',
          linhas: const [
            _LinhaConfig(rotulo: 'Versão do app', valor: '1.0.0', editavel: false),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () => _confirmarLogout(context, ref),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusErrorText),
            child: const Text('Sair da conta'),
          ),
        ),
      ],
    );
  }

  Future<void> _editarTexto(
    BuildContext context, {
    required String titulo,
    required String valorInicial,
    TextInputType? teclado,
    String? Function(String valor)? validador,
    required Future<bool> Function(String valor) onSalvar,
  }) async {
    final controller = TextEditingController(text: valorInicial);
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: teclado,
            autofocus: true,
            validator: (v) => validador?.call(v?.trim() ?? ''),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    final novoValor = controller.text.trim();
    if (novoValor == valorInicial) return;

    final sucesso = await onSalvar(novoValor);
    if (!sucesso && context.mounted) {
      _mostrarErro(context);
    }
  }

  Future<void> _alterarSenha(BuildContext context, ContaActionsController actions) async {
    final senhaController = TextEditingController();
    final confirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: senhaController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Use pelo menos 6 caracteres.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmarController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                validator: (v) =>
                    v != senhaController.text ? 'As senhas não coincidem.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    final sucesso = await actions.alterarSenha(senhaController.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(sucesso ? 'Senha alterada com sucesso.' : 'Não foi possível alterar a senha.'),
          ),
        );
    }
  }

  Future<void> _editarEndereco(
    BuildContext context,
    WidgetRef ref, {
    required Endereco endereco,
    required ContaActionsController actions,
  }) async {
    final cepController = TextEditingController(text: endereco.cep);
    final ruaController = TextEditingController(text: endereco.rua);
    final numeroController = TextEditingController(text: endereco.numero);
    final bairroController = TextEditingController(text: endereco.bairro);
    final cidadeController = TextEditingController(text: endereco.cidade);
    final ufController = TextEditingController(text: endereco.uf);
    final formKey = GlobalKey<FormState>();

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Endereço de coleta', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: cepController,
                decoration: const InputDecoration(labelText: 'CEP'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o CEP.' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: ruaController,
                      decoration: const InputDecoration(labelText: 'Rua'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe a rua.' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'Nº'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: bairroController,
                      decoration: const InputDecoration(labelText: 'Bairro'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: cidadeController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: ufController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                      decoration: const InputDecoration(labelText: 'UF', counterText: ''),
                      validator: (v) => (v == null || v.trim().length != 2) ? 'UF' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
                },
                child: const Text('Salvar endereço'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmado != true) return;
    final sucesso = await actions.atualizarEndereco(
      cep: cepController.text.trim(),
      rua: ruaController.text.trim(),
      numero: numeroController.text.trim(),
      bairro: bairroController.text.trim(),
      cidade: cidadeController.text.trim(),
      uf: ufController.text.trim().toUpperCase(),
    );
    if (!sucesso && context.mounted) {
      _mostrarErro(context);
    }
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

  void _mostrarErro(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar. Tente novamente.')),
      );
  }
}

class _SecaoConfig extends StatelessWidget {
  const _SecaoConfig({required this.titulo, required this.linhas, this.extra});

  final String titulo;
  final List<_LinhaConfig> linhas;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ...linhas,
              ?extra,
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaConfig extends StatelessWidget {
  const _LinhaConfig({
    required this.rotulo,
    this.valor,
    this.editavel = true,
    this.multilinha = false,
    this.onTap,
  });

  final String rotulo;
  final String? valor;
  final bool editavel;
  final bool multilinha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: editavel ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: multilinha
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(rotulo, style: textTheme.bodyMedium),
                      ),
                      if (editavel)
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.faint),
                    ],
                  ),
                  if (valor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      valor!,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  Text(rotulo, style: textTheme.bodyMedium),
                  const Spacer(),
                  if (valor != null)
                    Flexible(
                      child: Text(
                        valor!,
                        textAlign: TextAlign.right,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ),
                  if (editavel) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.faint),
                  ],
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

String _formatarData(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';
}
