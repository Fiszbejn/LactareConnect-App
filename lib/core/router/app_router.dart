import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cadastro_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/conta/presentation/conta_screen.dart';
import '../../features/conta/presentation/configuracoes_screen.dart';
import '../../features/faq/presentation/faq_screen.dart';
import '../session/session_controller.dart';
import 'app_routes.dart';
import 'home_shell.dart';
import 'placeholder_pages.dart';

/// Rotas acessíveis sem sessão válida — usadas tanto pra decidir se um
/// usuário deslogado pode ficar onde está quanto pra bloquear um usuário
/// já logado de voltar pra elas.
const _unauthenticatedRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.cadastro,
};

/// Ponte entre o `SessionController` (Riverpod) e o `refreshListenable`
/// do go_router (que espera um [Listenable]/`ChangeNotifier` clássico).
/// Sem isso, o go_router só reavalia o `redirect` quando o usuário navega
/// — não quando a sessão muda "sozinha" (ex: 401 em segundo plano).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  _GoRouterRefreshNotifier(Ref ref) {
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (session.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!session.isAuthenticatedAsNutriz) {
        return _unauthenticatedRoutes.contains(location)
            ? null
            : AppRoutes.welcome;
      }

      final isOnAuthOnlyRoute =
          location == AppRoutes.splash || _unauthenticatedRoutes.contains(location);
      return isOnAuthOnlyRoute ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPlaceholderPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.cadastro,
        builder: (context, state) => const CadastroScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const FaqScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.doar,
                builder: (context, state) =>
                    const TabPlaceholderPage(title: 'Doar'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) =>
                    const TabPlaceholderPage(title: 'Chat'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recompensas,
                builder: (context, state) =>
                    const TabPlaceholderPage(title: 'Recompensas'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conta,
                builder: (context, state) => const ContaScreen(),
                routes: [
                  GoRoute(
                    path: ConfiguracoesScreen.routePath,
                    builder: (context, state) => const ConfiguracoesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
