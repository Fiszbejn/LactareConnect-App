import 'package:flutter/material.dart';

/// Tela temporária só para validar o `redirect` do go_router enquanto a
/// sessão carrega — as 5 abas da home já têm tela real (ver `features/`).
class SplashPlaceholderPage extends StatelessWidget {
  const SplashPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
