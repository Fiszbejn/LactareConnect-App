class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const cadastro = '/cadastro';

  // Abas da home (StatefulShellRoute) — Início · Doar · Chat · Recompensas · Conta.
  static const home = '/';
  static const doar = '/doar';
  static const chat = '/chat';
  static const recompensas = '/recompensas';
  static const conta = '/conta';
  static const contaConfiguracoes = '/conta/configuracoes';
  static const meusResgates = '/recompensas/meus-resgates';
  static String recompensaDetalhe(int id) => '/recompensas/$id';

  static const doarMeusAgendamentos = '/doar/meus-agendamentos';
  static String doarAgendamento(int bancoId) => '/doar/agendamento/$bancoId';

  /// Índice da branch do Chat na `StatefulShellRoute` (`app_router.dart`) —
  /// usado por telas que precisam trocar de aba programaticamente, como o
  /// CTA "Abrir chat" da FAQ.
  static const chatBranchIndex = 2;
}
