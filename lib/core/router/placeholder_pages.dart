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

class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('TODO: home da doadora')));
  }
}
