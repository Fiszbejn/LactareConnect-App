import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Casca da home: hospeda as 5 abas (Início · Doar · Chat · Recompensas ·
/// Conta) num [Scaffold] fixo com [NavigationBar], enquanto o conteúdo de
/// cada aba é renderizado pelo [StatefulNavigationShell] do go_router.
///
/// Cada aba tem sua própria pilha de navegação interna — o
/// [StatefulNavigationShell] preserva o estado de cada uma ao trocar de aba
/// (ex: se a doadora abrir um sub-fluxo dentro de "Doar" e for pra "Chat",
/// ao voltar pra "Doar" ela retoma de onde parou).
class HomeShell extends StatelessWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Se a doadora tocar na aba em que já está, volta pro topo da
          // pilha daquela aba em vez de empilhar mais uma instância.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Doar',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Recompensas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}
