import 'package:flutter/material.dart';

/// Telas temporárias só para validar o `redirect` do go_router. Serão
/// substituídas pelas telas reais conforme as features forem implementadas
/// — login, welcome e cadastro já saíram daqui (ver `features/auth`).
class SplashPlaceholderPage extends StatelessWidget {
  const SplashPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Placeholder de conteúdo de uma aba da home, até a feature real
/// (doacao/conta/faq/chat/recompensas) ser implementada — ver
/// `HomeShell` pra a casca com a tab bar.
class TabPlaceholderPage extends StatelessWidget {
  const TabPlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$title\n(em breve)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
