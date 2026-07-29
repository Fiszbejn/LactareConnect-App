import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/auth_failure.dart';
import '../domain/cadastro_request.dart';
import 'cadastro_controller.dart';

const _totalSteps = 3;

/// Wizard de cadastro em 3 passos — Identidade e Contato são fiéis ao
/// wireframe `ScreenLoginStep1`/`ScreenLoginStep2` do Claude Design; o
/// passo de Senha foi acrescentado porque o wireframe original não previa
/// nenhum campo de senha (gap confirmado com o usuário).
///
/// Alguns campos também foram ajustados em relação ao wireframe pra bater
/// com o contrato real do backend (`CreateNutrizDto`/`CreateEnderecoDto`):
/// "Idade" virou "Data de nascimento", "Endereço completo" foi separado em
/// Rua + Número, e entraram os campos de E-mail e UF (nenhum dos dois
/// existia no desenho original).
class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  int _step = 0;

  final _formKeys = List.generate(_totalSteps, (_) => GlobalKey<FormState>());

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  DateTime? _dataNascimento;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  static String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _isAdult(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age >= 18;
  }

  Future<void> _pickDataNascimento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (picked == null) return;
    setState(() {
      _dataNascimento = picked;
      _dataNascimentoController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  void _goToNextStep() {
    if (!_formKeys[_step].currentState!.validate()) return;
    if (_step == _totalSteps - 1) {
      _submit();
      return;
    }
    setState(() => _step++);
  }

  void _goToPreviousStep() {
    if (_step == 0) {
      context.go(AppRoutes.welcome);
      return;
    }
    setState(() => _step--);
  }

  void _submit() {
    final request = CadastroRequest(
      nome: _nomeController.text.trim(),
      cpf: _onlyDigits(_cpfController.text),
      dataNascimento:
          '${_dataNascimento!.year.toString().padLeft(4, '0')}-'
          '${_dataNascimento!.month.toString().padLeft(2, '0')}-'
          '${_dataNascimento!.day.toString().padLeft(2, '0')}',
      telefone: _onlyDigits(_telefoneController.text),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      cep: _onlyDigits(_cepController.text),
      rua: _ruaController.text.trim(),
      numero: _numeroController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      uf: _ufController.text.trim().toUpperCase(),
    );
    ref.read(cadastroControllerProvider.notifier).register(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cadastroControllerProvider, (previous, next) {
      final error = next.error;
      if (next is AsyncError && error is AuthFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    });

    final isLoading = ref.watch(cadastroControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(step: _step, onBack: _goToPreviousStep),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKeys[_step],
                  child: switch (_step) {
                    0 => _buildIdentidadeStep(context),
                    1 => _buildContatoStep(context),
                    _ => _buildSegurancaStep(context),
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: _step == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _goToNextStep,
                        child: const Text('Continuar →'),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _goToPreviousStep,
                            child: const Text('Voltar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: isLoading ? null : _goToNextStep,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _step == _totalSteps - 1
                                        ? 'Finalizar cadastro'
                                        : 'Continuar →',
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentidadeStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Quem é você?', style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Vamos começar pelo básico. Bem-vinda. ✨',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _nomeController,
          decoration: const InputDecoration(labelText: 'Nome completo'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Informe seu nome.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CPF (documento oficial)',
            hintText: '000.000.000-00',
          ),
          validator: (v) => _onlyDigits(v ?? '').length == 11
              ? null
              : 'Informe um CPF válido.',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            hintText: 'seuemail@exemplo.com',
          ),
          validator: (v) {
            final email = v?.trim() ?? '';
            if (email.isEmpty) return 'Informe seu e-mail.';
            if (!email.contains('@') || !email.contains('.')) {
              return 'Informe um e-mail válido.';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _dataNascimentoController,
          readOnly: true,
          onTap: _pickDataNascimento,
          decoration: const InputDecoration(
            labelText: 'Data de nascimento',
            hintText: 'dd/mm/aaaa',
            suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
          ),
          validator: (_) {
            if (_dataNascimento == null) return 'Informe sua data de nascimento.';
            if (!_isAdult(_dataNascimento!)) {
              return 'É preciso ter 18 anos ou mais para doar.';
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Aceitamos doadoras a partir de 18 anos',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContatoStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Onde te encontramos?', style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Vamos usar isso para combinar coletas perto de você.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _telefoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            hintText: '(11) 9____-____',
          ),
          validator: (v) => _onlyDigits(v ?? '').length >= 10
              ? null
              : 'Informe um telefone válido.',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _cepController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
          ),
          validator: (v) =>
              _onlyDigits(v ?? '').length == 8 ? null : 'Informe um CEP válido.',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _ruaController,
                decoration: const InputDecoration(
                  labelText: 'Rua',
                  hintText: 'Nome da rua',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a rua.' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nº'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _bairroController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório.' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ufController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().length != 2) ? 'UF' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusPendingBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.statusPendingText.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('♡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Obrigado por dar o primeiro passo. Sua doação pode salvar vidas.',
                  style: textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegurancaStep(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Proteja sua conta', style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Defina uma senha para acessar sua conta depois.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _senhaController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Informe uma senha.';
            if (v.length < 6) return 'Use pelo menos 6 caracteres.';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _confirmarSenhaController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar senha'),
          validator: (v) =>
              v != _senhaController.text ? 'As senhas não coincidem.' : null,
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  'Cadastro',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${step + 1}/$_totalSteps',
                  textAlign: TextAlign.right,
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (step + 1) / _totalSteps,
              minHeight: 4,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
