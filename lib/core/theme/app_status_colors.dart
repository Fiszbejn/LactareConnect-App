import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores de status (ok / pendente / erro) usadas no checklist de exames,
/// feedback de FAQ, etc.
///
/// Não são cores "de marca" nem se encaixam nos slots do [ColorScheme]
/// padrão do Material (primary/secondary/error...), então em vez de
/// espalhar `AppColors.statusOkText` direto pelas telas, elas viram uma
/// [ThemeExtension]. Isso permite ler via `Theme.of(context).extension<AppStatusColors>()`
/// em qualquer widget — mesmo padrão do Material para adicionar tokens
/// próprios ao tema, com suporte a `lerp` (necessário se um dia tivermos
/// tema escuro com transição animada).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.okText,
    required this.okBg,
    required this.pendingText,
    required this.pendingBg,
    required this.errorText,
    required this.errorBg,
  });

  final Color okText;
  final Color okBg;
  final Color pendingText;
  final Color pendingBg;
  final Color errorText;
  final Color errorBg;

  static const light = AppStatusColors(
    okText: AppColors.statusOkText,
    okBg: AppColors.statusOkBg,
    pendingText: AppColors.statusPendingText,
    pendingBg: AppColors.statusPendingBg,
    errorText: AppColors.statusErrorText,
    errorBg: AppColors.statusErrorBg,
  );

  @override
  AppStatusColors copyWith({
    Color? okText,
    Color? okBg,
    Color? pendingText,
    Color? pendingBg,
    Color? errorText,
    Color? errorBg,
  }) {
    return AppStatusColors(
      okText: okText ?? this.okText,
      okBg: okBg ?? this.okBg,
      pendingText: pendingText ?? this.pendingText,
      pendingBg: pendingBg ?? this.pendingBg,
      errorText: errorText ?? this.errorText,
      errorBg: errorBg ?? this.errorBg,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      okText: Color.lerp(okText, other.okText, t)!,
      okBg: Color.lerp(okBg, other.okBg, t)!,
      pendingText: Color.lerp(pendingText, other.pendingText, t)!,
      pendingBg: Color.lerp(pendingBg, other.pendingBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
    );
  }
}
