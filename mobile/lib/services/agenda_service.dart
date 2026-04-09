import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/configuracao_agenda.dart';
import '../models/diarista_disponibilidade.dart';
import '../models/agendamento_diarista.dart';

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
}
