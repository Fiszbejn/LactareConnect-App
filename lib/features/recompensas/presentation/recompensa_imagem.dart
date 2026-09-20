import '../domain/recompensa.dart';

// Temporário (MVP): imagens embutidas no app, associadas pelo nome. Migrar
// para `Recompensa.imagemUrl` quando as imagens forem hospedadas.
const _imagensPorNome = {
  'Kit Cuidados Pós-Parto': 'assets/images/recompensas/kit-cuidados-pos-parto.jpg',
  'Almofada de Amamentação': 'assets/images/recompensas/almofada-amamentacao.jpg',
  'Vale Consulta Nutricional': 'assets/images/recompensas/vale-consulta-nutricional.jpg',
  'Desconto 20% Farmácia Parceira': 'assets/images/recompensas/desconto-20-farmacia-parceira.jpg',
  'Kit Chá e Bem-Estar': 'assets/images/recompensas/kit-cha-bem-estar.jpg',
  'Sessão de Massagem Relaxante': 'assets/images/recompensas/sessao-massagem-relaxante.jpg',
};

const recompensaImagemAspectRatio = 16 / 9;

String? imagemDaRecompensa(Recompensa recompensa) => _imagensPorNome[recompensa.nome.trim()];
