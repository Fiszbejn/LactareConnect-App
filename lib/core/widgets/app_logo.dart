import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Marca "Lactare connect" — globo com uma gota de leite no centro.
/// Recriação do `WFLogoMark`/`WFLogo` do Claude Design (SVG) via
/// [CustomPainter], já que o projeto ainda não tem pipeline de SVG.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.dark = false,
    this.showSubmark = true,
  });

  final double size;
  final bool dark;
  final bool showSubmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: const _LogoMarkPainter(),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lactare',
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.62,
                color: dark ? Colors.white : AppColors.ink,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
            if (showSubmark)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'CONNECT',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.32,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.brand,
                    letterSpacing: 3,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48);

    canvas.drawCircle(const Offset(24, 24), 19, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(24, 24),
      19,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final faintStroke = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24, 24), width: 38, height: 14),
      faintStroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 5)
        ..cubicTo(16, 14, 16, 34, 24, 43),
      faintStroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 5)
        ..cubicTo(32, 14, 32, 34, 24, 43),
      faintStroke,
    );

    final drop = Path()
      ..moveTo(24, 11)
      ..cubicTo(18, 18, 17, 24, 19, 28)
      ..arcToPoint(
        const Offset(29, 28),
        radius: const Radius.circular(5),
        clockwise: true,
      )
      ..cubicTo(31, 24, 30, 18, 24, 11)
      ..close();

    canvas.drawPath(
      drop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7FC8EE), AppColors.brandLight],
        ).createShader(const Rect.fromLTWH(14, 11, 20, 22)),
    );
    canvas.drawPath(
      drop,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(22, 19);
    canvas.rotate(-20 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 2.8, height: 5.2),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoMarkPainter oldDelegate) => false;
}
