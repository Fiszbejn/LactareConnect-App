import 'package:flutter/material.dart';

/// Tokens de cor do design system do LactareConnect (Claude Design).
///
/// Cores de status (ok/pending/erro) ficam fora daqui porque não fazem
/// parte do [ColorScheme] do Material — ver [AppStatusColors].
class AppColors {
  AppColors._();

  // Marca
  static const brand = Color(0xFF00458B);
  static const brandLight = Color(0xFF54B2E3);
  static const brandTint = Color(0xFFEAF4FB);

  // Neutros
  static const bg = Color(0xFFFAFAF7);
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B6B6B);
  static const faint = Color(0xFF9A9A9A);
  static const line = Color(0xFFD6D6D6);
  static const lineSoft = Color(0xFFE8E8E5);

  // Status (checklist de exames, feedback de FAQ, etc.)
  static const statusOkText = Color(0xFF1B7F79);
  static const statusOkBg = Color(0xFFE8F4F2);
  static const statusPendingText = Color(0xFFA07418);
  static const statusPendingBg = Color(0xFFFFF7E8);
  static const statusErrorText = Color(0xFFFF4858);
  static const statusErrorBg = Color(0xFFFFEEF0);

  // Acentos "opcionais" do design system, usados só pra diferenciar
  // categorias em listas filtráveis (ex: chips de categoria do FAQ).
  static const accentTeal = Color(0xFF1B7F79);
  static const accentPink = Color(0xFFF25CA2);
  static const accentAmber = Color(0xFFF2B33D);
  static const categoryAccents = [brand, brandLight, accentTeal, accentPink, accentAmber];
}
