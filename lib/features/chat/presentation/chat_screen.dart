import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/mensagem_chat.dart';
import 'chat_controller.dart';

/// Tela "Chat" — conversa com a Lila, sem histórico (ver
/// domain/chat_repository.dart pra por que): as mensagens somem quando a
/// nutriz sai do app, só ficam guardadas no backend pra auditoria.
/// Sem wireframe fiel de propósito — a Lila ainda não tem IA de verdade
/// (respostas fixas por enquanto, ver checkpoint do backend), então a tela
/// foi desenhada simples, seguindo os tokens do design system.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textoController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _textoController.text;
    if (texto.trim().isEmpty) return;
    _textoController.clear();
    ref.read(chatControllerProvider.notifier).enviar(texto);
  }

  void _rolarProFinal() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);

    ref.listen(chatControllerProvider, (previous, next) {
      final erro = next.erro;
      if (erro != null && erro != previous?.erro) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(erro)));
      }
      if (next.mensagens.length != previous?.mensagens.length || next.enviando != previous?.enviando) {
        _rolarProFinal();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AvatarLila(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lila'),
                Text(
                  'Assistente virtual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                const _BolhaBot(
                  texto:
                      'Oi! Eu sou a Lila 💙 Estou aqui pra tirar suas dúvidas sobre doação de leite '
                      'humano. Pode perguntar o que quiser.',
                ),
                for (final mensagem in chat.mensagens)
                  mensagem.remetente == RemetenteMensagem.usuario
                      ? _BolhaUsuario(mensagem: mensagem)
                      : _BolhaBot(texto: mensagem.texto, timestamp: mensagem.timestamp),
                if (chat.enviando) const _BolhaDigitando(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(hintText: 'Escreva sua mensagem...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.brand,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: chat.enviando ? null : _enviar,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarLila extends StatelessWidget {
  const _AvatarLila();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _BolhaUsuario extends StatelessWidget {
  const _BolhaUsuario({required this.mensagem});

  final MensagemChat mensagem;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
        ),
        child: Text(mensagem.texto, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _BolhaBot extends StatelessWidget {
  const _BolhaBot({required this.texto, this.timestamp});

  final String texto;
  final DateTime? timestamp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto, style: const TextStyle(color: AppColors.ink)),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                // timestamp vem em UTC do backend — sem toLocal(), o
                // horário mostrado ficaria errado (ex: 3h a menos no Brasil).
                DateFormat.Hm('pt_BR').format(timestamp!.toLocal()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.faint, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BolhaDigitando extends StatelessWidget {
  const _BolhaDigitando();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: const SizedBox(
          width: 16,
          height: 10,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.faint),
            ),
          ),
        ),
      ),
    );
  }
}
