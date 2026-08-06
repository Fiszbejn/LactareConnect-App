import 'agendamento.dart';
import 'banco_leite.dart';
import 'exame_pre_doacao.dart';

/// Contrato de acesso aos dados de Doar — a implementação real (Dio) fica
/// em `data/`.
abstract class DoacaoRepository {
  Future<List<BancoLeite>> getBancos();

  Future<List<ExamePreDoacao>> getMeusExames();

  /// Envia o comprovante de um exame — cria o registro se a nutriz ainda
  /// não tem um pra esse [tipo] ([exameIdExistente] nulo), ou atualiza se
  /// já existir. Marca `status: ok` direto (o backend não tem uma etapa de
  /// análise real, só exige `arquivoUrl` preenchido pra aceitar "ok").
  Future<void> enviarExame({
    required int nutrizId,
    required ExameTipo tipo,
    required String arquivoUrl,
    int? exameIdExistente,
  });

  /// Agenda a coleta em [bancoId]. Lança [DoacaoFailure] com a mensagem
  /// pronta do backend se algum dos 4 exames obrigatórios ainda não
  /// estiver "ok" (`POST /agendamentos` responde 400 nesse caso).
  Future<void> criarAgendamento({
    required int nutrizId,
    required int bancoId,
    required DateTime dataColeta,
    required String horario,
  });

  Future<List<Agendamento>> getMeusAgendamentos();

  /// Marca o agendamento como `realizado` — pré-requisito do backend pra
  /// permitir `POST /doacoes` a partir dele.
  Future<void> confirmarColetaRealizada(int agendamentoId);

  /// Registra a doação a partir de um agendamento `realizado`, o que
  /// credita 100 gotinhas automaticamente no backend.
  Future<void> registrarDoacao({
    required int nutrizId,
    required int agendamentoId,
    required int volumeMl,
    required DateTime dataColeta,
  });
}
