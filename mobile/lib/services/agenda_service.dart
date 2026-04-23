import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/configuracao_agenda.dart';
import '../models/diarista_disponibilidade.dart';
import '../models/agendamento_diarista.dart';
import '../models/bloqueio_recorrente.dart';

/// Service responsável pelo CRUD da agenda no Supabase
class AgendaService {
  final _supabase = Supabase.instance.client;

  // ─── DISPONIBILIDADE ─────────────────────────────────────────────────────

  /// Busca disponibilidade de uma diarista num intervalo de datas
  Future<List<DiaristaDisponibilidade>> getDisponibilidade({
    required String diaristaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    try {
      final response = await _supabase
          .from('diarista_disponibilidade')
          .select()
          .eq('diarista_id', diaristaId)
          .gte('data', inicio.toIso8601String().split('T')[0])
          .lte('data', fim.toIso8601String().split('T')[0])
          .order('data');

      return (response as List)
          .map((e) =>
              DiaristaDisponibilidade.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar disponibilidade: $e');
    }
  }

  /// Salva ou atualiza a disponibilidade de um dia (upsert)
  Future<void> salvarDisponibilidade({
    required String diaristaId,
    required DateTime data,
    required StatusDisponibilidade status,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFim,
    String? notas,
  }) async {
    try {
      final dataStr = data.toIso8601String().split('T')[0];
      final payload = <String, dynamic>{
        'diarista_id': diaristaId,
        'data': dataStr,
        'status': status.name,
        'hora_inicio': horaInicio != null
            ? '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}'
            : null,
        'hora_fim': horaFim != null
            ? '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}'
            : null,
        'notas': notas,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('diarista_disponibilidade')
          .upsert(payload, onConflict: 'diarista_id,data');
    } catch (e) {
      throw Exception('Erro ao salvar disponibilidade: $e');
    }
  }

  /// Remove disponibilidade de um dia (reverte para bloqueado implícito)
  Future<void> removerDisponibilidade({
    required String diaristaId,
    required DateTime data,
  }) async {
    try {
      final dataStr = data.toIso8601String().split('T')[0];
      await _supabase
          .from('diarista_disponibilidade')
          .delete()
          .eq('diarista_id', diaristaId)
          .eq('data', dataStr);
    } catch (e) {
      throw Exception('Erro ao remover disponibilidade: $e');
    }
  }

  // ─── AGENDAMENTOS ─────────────────────────────────────────────────────────

  /// Busca agendamentos de uma diarista num intervalo de datas
  Future<List<AgendamentoDiarista>> getAgendamentos({
    required String diaristaId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    try {
      final response = await _supabase
          .from('agendamentos_diarista')
          .select()
          .eq('diarista_id', diaristaId)
          .gte('data_agendamento', inicio.toIso8601String().split('T')[0])
          .lte('data_agendamento', fim.toIso8601String().split('T')[0])
          .order('data_agendamento');

      return (response as List)
          .map((e) => AgendamentoDiarista.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar agendamentos: $e');
    }
  }

  /// Confirma ou recusa um agendamento (diarista)
  Future<void> atualizarStatusAgendamento({
    required String agendamentoId,
    required StatusAgendamento status,
  }) async {
    try {
      await _supabase.from('agendamentos_diarista').update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', agendamentoId);
    } catch (e) {
      throw Exception('Erro ao atualizar agendamento: $e');
    }
  }

  /// Cria nova solicitação de agendamento (pelo cliente)
  Future<String> criarSolicitacaoAgendamento({
    required String diaristaId,
    required String clienteId,
    required DateTime data,
    required TipoServico tipoServico,
    required String endereco,
    String? observacoes,
    double? valorAcordado,
  }) async {
    try {
      // Horários baseados no tipo
      final horaInicio = const TimeOfDay(hour: 8, minute: 0);
      final horaFim = tipoServico == TipoServico.meioPeriodo
          ? const TimeOfDay(hour: 12, minute: 0)
          : const TimeOfDay(hour: 17, minute: 0);

      final payload = {
        'diarista_id': diaristaId,
        'cliente_id': clienteId,
        'data_agendamento': data.toIso8601String().split('T')[0],
        'horario_inicio':
            '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
        'horario_fim':
            '${horaFim.hour.toString().padLeft(2, '0')}:${horaFim.minute.toString().padLeft(2, '0')}',
        'tipo_servico': tipoServico.name,
        'status': StatusAgendamento.pendente.name,
        'endereco': endereco,
        'observacoes': observacoes,
        'valor_acordado': valorAcordado,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('agendamentos_diarista')
          .insert(payload)
          .select('id');

      return response.first['id'] as String;
    } catch (e) {
      throw Exception('Erro ao criar agendamento: $e');
    }
  }

  /// Conta agendamentos confirmados num dia específico
  Future<int> contarAgendamentosNaData({
    required String diaristaId,
    required DateTime data,
  }) async {
    try {
      final dataStr = data.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('agendamentos_diarista')
          .select('id')
          .eq('diarista_id', diaristaId)
          .eq('data_agendamento', dataStr)
          .filter('status', 'in', '("confirmado","em_progresso")');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ─── BLOQUEIOS RECORRENTES ────────────────────────────────────────────────

  /// Busca todas as regras de bloqueio recorrente da diarista (apenas ativas)
  Future<List<BloqueioRecorrente>> getBloqueiosRecorrentes({
    required String diaristaId,
  }) async {
    try {
      final response = await _supabase
          .from('diarista_bloqueio_recorrente')
          .select()
          .eq('diarista_id', diaristaId)
          .eq('ativo', true)
          .order('criado_em');

      return (response as List)
          .map((e) => BloqueioRecorrente.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [ERROR] getBloqueiosRecorrentes: $e');
      return [];
    }
  }

  /// Cria uma nova regra de bloqueio recorrente
  Future<void> salvarBloqueioRecorrente({
    required String diaristaId,
    required TipoRecorrencia tipo,
    required int valor,
    required DateTime dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final payload = <String, dynamic>{
        'diarista_id': diaristaId,
        'tipo': tipo.name,
        'valor': valor,
        'data_inicio': dataInicio.toIso8601String().split('T')[0],
        'data_fim': dataFim?.toIso8601String().split('T')[0],
      };
      await _supabase
          .from('diarista_bloqueio_recorrente')
          .insert(payload);
    } catch (e) {
      throw Exception('Erro ao salvar bloqueio recorrente: $e');
    }
  }

  /// Remove uma regra de bloqueio recorrente pelo id
  Future<void> removerBloqueioRecorrente({required String id}) async {
    try {
      await _supabase
          .from('diarista_bloqueio_recorrente')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao remover bloqueio recorrente: $e');
    }
  }

  /// Remove todos os bloqueios semanais ativos de um dia da semana específico
  Future<void> removerBloqueioSemanal({
    required String diaristaId,
    required int diaSemana,
  }) async {
    try {
      await _supabase
          .from('diarista_bloqueio_recorrente')
          .delete()
          .eq('diarista_id', diaristaId)
          .eq('tipo', 'semanal')
          .eq('valor', diaSemana);
    } catch (_) {}
  }

  // ─── CONFIGURAÇÃO DE JORNADA ──────────────────────────────────────────────

  /// Retorna a jornada configurada pela diarista (ou null se não definida).
  Future<ConfiguracaoAgenda?> getConfiguracaoAgenda(String diaristaId) async {
    try {
      final response = await _supabase
          .from('configuracoes_agenda')
          .select()
          .eq('diarista_id', diaristaId)
          .maybeSingle();
      if (response == null) return null;
      return ConfiguracaoAgenda.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Salva / atualiza a jornada de trabalho da diarista.
  Future<void> salvarConfiguracaoAgenda({
    required String diaristaId,
    required TimeOfDay horaInicio,
    required TimeOfDay horaFim,
    int tempoDeslocamentoMinutos = 30,
    List<int>? diasTrabalho,
  }) async {
    await _supabase.from('configuracoes_agenda').upsert(
      {
        'diarista_id': diaristaId,
        'hora_inicio_padrao': _fmtHora(horaInicio),
        'hora_fim_padrao': _fmtHora(horaFim),
        'tempo_deslocamento_minutos': tempoDeslocamentoMinutos,
        if (diasTrabalho != null) 'dias_trabalho': diasTrabalho,
      },
      onConflict: 'diarista_id',
    );
  }

  // ─── HORÁRIOS DISPONÍVEIS ─────────────────────────────────────────────────

  /// Gera a lista de horários disponíveis para uma diarista em uma data.
  ///
  /// Leva em conta:
  /// * A jornada configurada (hora_inicio / hora_fim)
  /// * Agendamentos confirmados já existentes no dia
  /// * Solicitações aceitas/em_andamento já existentes no dia
  ///
  /// Slots são gerados de 30 em 30 minutos dentro da janela disponível.
  Future<List<TimeOfDay>> getHorariosDisponiveis({
    required String diaristaId,
    required DateTime data,
    required int duracaoMinutos,
  }) async {
    // 1. Jornada da diarista (fallback: 08:00-17:00)
    final config = await getConfiguracaoAgenda(diaristaId);
    final jornadaInicio =
        config?.horaInicioPadrao ?? const TimeOfDay(hour: 8, minute: 0);
    final jornadaFim =
        config?.horaFimPadrao ?? const TimeOfDay(hour: 17, minute: 0);

    // 2. Se o dia não está nos dias de trabalho → sem slots
    final diaSemana = data.weekday % 7; // 0=Dom...6=Sab
    if (config != null && !config.diasTrabalho.contains(diaSemana)) {
      return [];
    }

    // 3. Se existe bloqueio manual para esse dia específico → sem slots
    final dataStr = data.toIso8601String().split('T')[0];
    try {
      final dispResp = await _supabase
          .from('diarista_disponibilidade')
          .select('status')
          .eq('diarista_id', diaristaId)
          .eq('data', dataStr)
          .maybeSingle();
      if (dispResp != null && dispResp['status'] == 'bloqueado') return [];
    } catch (_) {}

    // 4. Se existe bloqueio recorrente ativo para esse dia da semana → sem slots
    final recorrentes = await getBloqueiosRecorrentes(diaristaId: diaristaId);
    final temBloqueioRecorrente =
        recorrentes.any((r) => r.aplicaNaData(data));
    // Manual override (status != bloqueado acima) libera mesmo com recorrente
    // (já checamos manual acima, se chegou aqui sem retornar, não há bloqueio manual)
    if (temBloqueioRecorrente) return [];

    final jornadaInicioMin =
        jornadaInicio.hour * 60 + jornadaInicio.minute;
    final jornadaFimMin = jornadaFim.hour * 60 + jornadaFim.minute;

    // 5. Buscar agendamentos do dia
    final agendamentos = await getAgendamentos(
      diaristaId: diaristaId,
      inicio: data,
      fim: data,
    );

    // 6. Buscar solicitações aceitas/em_andamento do dia com duracao_minutos
    final List<(int, int)> ocupados = [];

    for (final a in agendamentos) {
      if (a.status != StatusAgendamento.cancelado &&
          a.status != StatusAgendamento.finalizado) {
        final s = a.horarioInicio.hour * 60 + a.horarioInicio.minute;
        final e = a.horarioFim.hour * 60 + a.horarioFim.minute;
        ocupados.add((s, e));
      }
    }

    try {
      final sols = await _supabase
          .from('solicitacoes')
          .select('data_agendada, duracao_minutos')
          .eq('diarista_id', diaristaId)
          .like('data_agendada', '$dataStr%')
          .filter('status', 'in', '("aceita","em_andamento")');

      for (final sol in sols as List) {
        final dt = DateTime.parse(sol['data_agendada'] as String);
        final dur = (sol['duracao_minutos'] as num?)?.toInt() ?? 120;
        final s = dt.hour * 60 + dt.minute;
        ocupados.add((s, s + dur));
      }
    } catch (_) {}

    // 7. Gerar slots de 30 em 30 min
    final now = DateTime.now();
    final isToday = data.year == now.year &&
        data.month == now.month &&
        data.day == now.day;
    final nowMin = isToday ? now.hour * 60 + now.minute + 60 : 0;

    final slots = <TimeOfDay>[];
    for (int m = jornadaInicioMin;
        m + duracaoMinutos <= jornadaFimMin;
        m += 30) {
      if (isToday && m < nowMin) continue;
      final slotFim = m + duracaoMinutos;
      final conflito = ocupados.any((o) => m < o.$2 && slotFim > o.$1);
      if (!conflito) {
        slots.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
      }
    }

    return slots;
  }

  String _fmtHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
