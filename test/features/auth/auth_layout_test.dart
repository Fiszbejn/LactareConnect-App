import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lactareconnect_app/core/theme/app_theme.dart';
import 'package:lactareconnect_app/features/auth/presentation/cadastro_screen.dart';
import 'package:lactareconnect_app/features/auth/presentation/login_screen.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  double keyboardHeight = 0,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const smallPhone = Size(360, 640);

  group('LoginScreen', () {
    testWidgets('não estoura o layout com o teclado aberto', (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        size: smallPhone,
        keyboardHeight: 300,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('não estoura o layout com fonte ampliada', (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        size: smallPhone,
        keyboardHeight: 300,
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('mantém "Cadastre-se" visível e tocável em tela estreita',
        (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        size: const Size(320, 740),
        textScale: 1.3,
      );

      final button = find.widgetWithText(TextButton, 'Cadastre-se');
      expect(button, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(button).height, lessThan(48));
    });
  });

  group('CadastroScreen', () {
    Future<void> goToContatoStep(WidgetTester tester) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'),
        'Maria',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'CPF (documento oficial)'),
        '12345678901',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'maria@exemplo.com',
      );
      await tester.tap(find.widgetWithText(TextFormField, 'Data de nascimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar →'));
      await tester.pumpAndSettle();
    }

    testWidgets('campo UF tem largura suficiente pra exibir o label',
        (tester) async {
      await _pump(tester, const CadastroScreen(), size: const Size(360, 780));
      await goToContatoStep(tester);

      final ufField = find.widgetWithText(TextFormField, 'UF');
      expect(ufField, findsOneWidget);
      expect(tester.getSize(ufField).width, greaterThanOrEqualTo(72));
    });
  });
}
