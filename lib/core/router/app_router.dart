import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/session_controller.dart';
import 'app_routes.dart';
import 'placeholder_pages.dart';

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
        return location == AppRoutes.login ? null : AppRoutes.login;
      }

      final isOnAuthOnlyRoute =
          location == AppRoutes.splash || location == AppRoutes.login;
      return isOnAuthOnlyRoute ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPlaceholderPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPlaceholderPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePlaceholderPage(),
      ),
    ],
  );
});
