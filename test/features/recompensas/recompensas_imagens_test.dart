import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lactareconnect_app/core/theme/app_theme.dart';
import 'package:lactareconnect_app/features/recompensas/domain/recompensa.dart';
import 'package:lactareconnect_app/features/recompensas/presentation/recompensa_imagem.dart';
import 'package:lactareconnect_app/features/recompensas/presentation/recompensas_controller.dart';
import 'package:lactareconnect_app/features/recompensas/presentation/recompensas_screen.dart';

const _nomes = [
  'Kit Cuidados Pós-Parto',
  'Almofada de Amamentação',
  'Vale Consulta Nutricional',
  'Desconto 20% Farmácia Parceira',
  'Kit Chá e Bem-Estar',
  'Sessão de Massagem Relaxante',
];

Recompensa _recompensa(int id, String nome, {int estoque = 5}) => Recompensa(
      id: id,
      nome: nome,
      parceiro: 'Parceiro',
      categoria: 'autocuidado',
      custoGotinhas: 100,
      estoque: estoque,
      ativo: true,
      imagemUrl: null,
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('toda recompensa do catálogo tem imagem e o arquivo existe', () {
    for (var i = 0; i < _nomes.length; i++) {
      final asset = imagemDaRecompensa(_recompensa(i, _nomes[i]));
      expect(asset, isNotNull, reason: _nomes[i]);
      expect(File(asset!).existsSync(), isTrue, reason: asset);
    }
  });

  test('recompensa desconhecida não tem imagem', () {
    expect(imagemDaRecompensa(_recompensa(99, 'Outra coisa')), isNull);
  });

  for (final config in [
    (largura: 320.0, escala: 1.0),
    (largura: 360.0, escala: 1.3),
    (largura: 412.0, escala: 1.0),
  ]) {
    testWidgets(
      'grid de recompensas não estoura na vertical em ${config.largura}px com fonte ${config.escala}x',
      (tester) async {
        tester.view.physicalSize = Size(config.largura, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final erros = <String>[];
        final onErrorOriginal = FlutterError.onError;
        FlutterError.onError = (details) => erros.add(details.exceptionAsString());
        addTearDown(() => FlutterError.onError = onErrorOriginal);

        final dados = RecompensasData(
          saldoGotinhas: 250,
          recompensas: [
            for (var i = 0; i < _nomes.length; i++)
              _recompensa(i, _nomes[i], estoque: i == 1 ? 0 : 5),
          ],
          enderecoResumo: null,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recompensasProvider.overrideWith((ref) async => dados),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(config.escala),
                ),
                child: child!,
              ),
              home: const RecompensasScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(erros.where((e) => e.contains('on the bottom')), isEmpty);
        expect(find.byType(Image), findsWidgets);
      },
    );
  }
}
