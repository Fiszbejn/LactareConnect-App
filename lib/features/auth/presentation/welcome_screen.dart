import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';

/// Tela de entrada do app (fiel ao wireframe `ScreenWelcome` do Claude
/// Design) — decide entre "Quero ser doadora" (cadastro) e "Já tenho
/// cadastro" (login). Sem lógica própria, só navegação.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(size: 26),
                  Text(
                    'PT-BR',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _HeroPlaceholder(),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  style: textTheme.headlineLarge,
                  children: [
                    const TextSpan(text: 'Cada gota\ntem um destino\n'),
                    TextSpan(
                      text: 'especial.',
                      style: TextStyle(color: AppColors.brand),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Doe leite materno e ajude bebês que mais precisam. '
                'Você não está sozinha nessa jornada.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.cadastro),
                child: const Text('Quero ser doadora'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Já tenho cadastro'),
              ),
              const SizedBox(height: 16),
              Text(
                'Aprovado pelo Banco de Leite Humano',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Substitui a foto real do wireframe (`assets/welcome_mae_bebe.jpg`), que
/// ainda não existe no projeto — gradiente de marca como placeholder até
/// termos o asset definitivo.
class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandLight, AppColors.brand],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
    );
  }
}
