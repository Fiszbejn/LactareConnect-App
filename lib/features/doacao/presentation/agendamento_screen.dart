import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/doacao_failure.dart';
import '../domain/exame_pre_doacao.dart';
import 'doacao_controller.dart';

enum _OrigemArquivo { arquivo, camera }

/// Agendar coleta em [bancoId] — checklist dos 4 exames obrigatórios (ver
/// domain/exame_pre_doacao.dart) + seleção de dia/horário livre (o
/// backend não tem endpoint de disponibilidade real, então não há grade
/// de horários "ocupados/livres" fingida aqui, só uma lista de horários
/// comuns pra facilitar a escolha).
class AgendamentoScreen extends ConsumerStatefulWidget {
  const AgendamentoScreen({required this.bancoId, super.key});

  static const routePath = 'agendamento/:bancoId';

  final int bancoId;

  @override
  ConsumerState<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends ConsumerState<AgendamentoScreen> {
  static const _horariosSugeridos = ['08:00', '09:30', '11:00', '13:30', '15:00', '16:30'];

  DateTime? _dataSelecionada;
  String? _horarioSelecionado;

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: agora.add(const Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 60)),
      helpText: 'Escolha o dia da coleta',
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  Future<void> _enviarExame(ExameTipo tipo, ExamePreDoacao? existente) async {
    final origem = await showModalBottomSheet<_OrigemArquivo>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.brand),
              title: const Text('Anexar arquivo'),
              onTap: () => Navigator.of(context).pop(_OrigemArquivo.arquivo),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.brand),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.of(context).pop(_OrigemArquivo.camera),
            ),
          ],
        ),
      ),
    );
    if (origem == null || !mounted) return;

    // Não existe upload real no backend (`arquivoUrl` é só texto, ver
    // domain/doacao_repository.dart) — o caminho do arquivo escolhido no
    // aparelho vira esse texto fictício, só pra destravar o checklist.
    String? caminho;
    if (origem == _OrigemArquivo.camera) {
      final foto = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
      caminho = foto?.path;
    } else {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final arquivo = resultado?.files.single;
      caminho = arquivo?.path ?? arquivo?.name;
    }
    if (caminho == null || !mounted) return;

    await ref.read(exameUploadControllerProvider.notifier).enviar(
      tipo: tipo,
      arquivoUrl: caminho,
      exameIdExistente: existente?.id,
    );
  }

  Future<void> _confirmarAgendamento() async {
    final sucesso = await ref.read(agendamentoControllerProvider.notifier).agendar(
      bancoId: widget.bancoId,
      dataColeta: _dataSelecionada!,
      horario: _horarioSelecionado!,
    );
    if (!mounted || !sucesso) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coleta agendada!')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final examesAsync = ref.watch(meusExamesProvider);
    final enviandoExame = ref.watch(exameUploadControllerProvider).isLoading;
    final agendando = ref.watch(agendamentoControllerProvider).isLoading;

    ref.listen(exameUploadControllerProvider, (previous, next) {
      final error = next.error;
      if (next is AsyncError && error is DoacaoFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    });
    ref.listen(agendamentoControllerProvider, (previous, next) {
      final error = next.error;
      if (next is AsyncError && error is DoacaoFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar coleta')),
      body: examesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Não foi possível carregar seus exames.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ),
        data: (exames) {
          final porTipo = <ExameTipo, ExamePreDoacao>{for (final e in exames) e.tipoExame: e};
          final enviados = ExameTipo.values.where((t) => porTipo[t]?.status == ExameStatus.ok).length;
          final todosOk = enviados == ExameTipo.values.length;
          final podeAgendar =
              todosOk && _dataSelecionada != null && _horarioSelecionado != null && !agendando;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Row(
                      children: [
                        Text('Exames pré-doação', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '$enviados de ${ExameTipo.values.length} enviados',
                          style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: enviados / ExameTipo.values.length,
                        minHeight: 4,
                        backgroundColor: AppColors.lineSoft,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandLight.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Por que pedimos? Os exames protegem você e os bebês que vão receber sua doação. São pedidos só uma vez.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          for (final tipo in ExameTipo.values)
                            _ExameTile(
                              tipo: tipo,
                              exame: porTipo[tipo],
                              ultimo: tipo == ExameTipo.values.last,
                              enviando: enviandoExame,
                              onEnviar: () => _enviarExame(tipo, porTipo[tipo]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Escolha um dia para a coleta', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _escolherData,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(
                        _dataSelecionada == null
                            ? 'Selecionar data'
                            : DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_dataSelecionada!),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Horário disponível em casa', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final horario in _horariosSugeridos)
                          ChoiceChip(
                            label: Text(horario),
                            selected: _horarioSelecionado == horario,
                            onSelected: (_) => setState(() => _horarioSelecionado = horario),
                            selectedColor: AppColors.brandTint,
                            labelStyle: TextStyle(
                              color: _horarioSelecionado == horario ? AppColors.brand : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: _horarioSelecionado == horario ? AppColors.brand : AppColors.line,
                            ),
                          ),
                      ],
                    ),
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
                  onPressed: podeAgendar ? _confirmarAgendamento : null,
                  child: agendando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(
                          !todosOk
                              ? 'Envie os exames pendentes pra continuar'
                              : 'Confirmar agendamento',
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExameTile extends StatelessWidget {
  const _ExameTile({
    required this.tipo,
    required this.exame,
    required this.ultimo,
    required this.enviando,
    required this.onEnviar,
  });

  final ExameTipo tipo;
  final ExamePreDoacao? exame;
  final bool ultimo;
  final bool enviando;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final status = exame?.status ?? ExameStatus.faltando;
    final isOk = status == ExameStatus.ok;
    final cor = switch (status) {
      ExameStatus.ok => AppColors.statusOkText,
      ExameStatus.pendente => AppColors.statusPendingText,
      ExameStatus.faltando => AppColors.statusErrorText,
    };
    final fundo = switch (status) {
      ExameStatus.ok => AppColors.statusOkBg,
      ExameStatus.pendente => AppColors.statusPendingBg,
      ExameStatus.faltando => AppColors.statusErrorBg,
    };
    final icone = isOk ? Icons.check : (status == ExameStatus.pendente ? Icons.hourglass_top : Icons.priority_high);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: ultimo ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icone, size: 13, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tipo.label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (!isOk)
            OutlinedButton(
              onPressed: enviando ? null : onEnviar,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Enviar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
