import 'package:flutter/material.dart';

/// Telas temporárias só para validar o `redirect` do go_router. Serão
/// substituídas pelas telas reais quando construirmos a feature `auth`
/// (login, wizard de cadastro) e a home com a tab bar de 5 abas.
class SplashPlaceholderPage extends StatelessWidget {
  const SplashPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class LoginPlaceholderPage extends StatelessWidget {
  const LoginPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('TODO: tela de login')));
  }
}

class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('TODO: home da doadora')));
  }
}
