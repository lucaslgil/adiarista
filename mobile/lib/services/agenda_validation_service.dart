import 'package:flutter/material.dart';
import '../models/agendamento_diarista.dart';
import '../models/diarista_disponibilidade.dart';
import '../models/configuracao_agenda.dart';

/// Service de Validação de Agenda
///
/// Contém todas as regras de negócio para:
/// - Validar disponibilidade
/// - Agendar serviços
/// - Gerenciar horários
class AgendaValidationService {
  /// Validar se é possível agendar um novo serviço
  ///
  /// Regras:
  /// 1. Se INTEGRAL: não pode ter nenhum agendamento confirmado no dia
  /// 2. Se MEIO_PERÍODO: pode ter até 1 outro agendamento de meio período
  static ValidationResult validarAgendamento({
    required DateTime data,
    required TipoServico tipoServico,
    required TimeOfDay inicio,
    required TimeOfDay fim,
    required List<AgendamentoDiarista> agendamentosExistentes,
    required DiaristaDisponibilidade disponibilidade,
    int tempoDeslocamentoMinutos = 30,
  }) {
    // 1. Validar se a data está bloqueada
    if (disponibilidade.status == StatusDisponibilidade.bloqueado) {
      return ValidationResult(
        valido: false,
        mensagem: 'Dia bloqueado para agendamentos',
      );
    }

    // 2. Filtrar agendamentos da mesma data que estão confirmados
    final agendamentosConfirmados = agendamentosExistentes
        .where((a) =>
            a.dataAgendamento == data &&
            (a.status == StatusAgendamento.confirmado ||
                a.status == StatusAgendamento.emProgresso))
        .toList();

    // 3. Se INTEGRAL: não pode ter nenhum agendamento
    if (tipoServico == TipoServico.integral) {
      if (agendamentosConfirmados.isNotEmpty) {
        return ValidationResult(
          valido: false,
          mensagem:
              'Não é possível agendar período integral. Já existe ${agendamentosConfirmados.length} serviço(s) agendado(s).',
        );
      }
    }

    // 4. Se MEIO_PERÍODO: pode ter apenas 1 confirmado
    if (tipoServico == TipoServico.meioPeriodo) {
      if (agendamentosConfirmados.length >= 2) {
        return ValidationResult(
          valido: false,
          mensagem:
              'Não é possível agendar. Já existem 2 serviços de meio período no dia.',
        );
      }
    }

    // 5. Validar se há sobreposição de horários
    final temSobreposicao = _verificarSobreposicao(
      inicio,
      fim,
      agendamentosConfirmados,
      tempoDeslocamentoMinutos,
    );

    if (temSobreposicao) {
      return ValidationResult(
        valido: false,
        mensagem:
            'Horário conflita com outro agendamento. Considere tempo de deslocamento.',
      );
    }

    // 6. Validar se o horário respeita a disponibilidade
    if (!_horarioNaDisponibilidade(
      inicio,
      fim,
      disponibilidade.horaInicio,
      disponibilidade.horaFim,
    )) {
      final horaInicio = disponibilidade.horaInicio != null
          ? '${disponibilidade.horaInicio!.hour.toString().padLeft(2, '0')}:${disponibilidade.horaInicio!.minute.toString().padLeft(2, '0')}'
          : '08:00';
      final horaFim = disponibilidade.horaFim != null
          ? '${disponibilidade.horaFim!.hour.toString().padLeft(2, '0')}:${disponibilidade.horaFim!.minute.toString().padLeft(2, '0')}'
          : '18:00';
      return ValidationResult(
        valido: false,
        mensagem: 'Horário fora da disponibilidade ($horaInicio - $horaFim)',
      );
    }

    return ValidationResult(
      valido: true,
      mensagem: 'Agendamento válido',
    );
  }

  /// Verificar se há sobreposição entre o novo horário e os agendados
  static bool _verificarSobreposicao(
    TimeOfDay novoInicio,
    TimeOfDay novoFim,
    List<AgendamentoDiarista> agendamentos,
    int tempoDeslocamentoMinutos,
  ) {
    final novoInicioMinutos = _timeToMinutes(novoInicio);
    final novoFimMinutos = _timeToMinutes(novoFim) + tempoDeslocamentoMinutos;

    for (final agendado in agendamentos) {
      final agendadoInicioMinutos =
          _timeToMinutes(agendado.horarioInicio) - tempoDeslocamentoMinutos;
      final agendadoFimMinutos = _timeToMinutes(agendado.horarioFim);

      // Verificar se há sobreposição
      if (novoInicioMinutos < agendadoFimMinutos &&
          novoFimMinutos > agendadoInicioMinutos) {
        return true;
      }
    }

    return false;
  }

  /// Verificar se o horário está dentro da disponibilidade
  static bool _horarioNaDisponibilidade(
    TimeOfDay horarioInicio,
    TimeOfDay horarioFim,
    TimeOfDay? disponibilidadeInicio,
    TimeOfDay? disponibilidadeFim,
  ) {
    if (disponibilidadeInicio == null || disponibilidadeFim == null) {
      return true; // Se não houver restrição, permite
    }

    final novoInicioMinutos = _timeToMinutes(horarioInicio);
    final novoFimMinutos = _timeToMinutes(horarioFim);
    final dispInicioMinutos = _timeToMinutes(disponibilidadeInicio);
    final dispFimMinutos = _timeToMinutes(disponibilidadeFim);

    return novoInicioMinutos >= dispInicioMinutos &&
        novoFimMinutos <= dispFimMinutos;
  }

  /// Converter TimeOfDay para minutos desde 00:00
  static int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Obter próximos horários disponíveis para meio período
  static List<SlotDisponivel> obterSlotsDisponiveis({
    required DateTime data,
    required TimeOfDay inicio,
    required TimeOfDay fim,
    required List<AgendamentoDiarista> agendamentosExistentes,
    int duracaoMinutos = 240, // 4 horas
  }) {
    final slots = <SlotDisponivel>[];
    final dataAgendamentos = agendamentosExistentes
        .where((a) =>
            a.dataAgendamento == data &&
            a.status == StatusAgendamento.confirmado)
        .toList();

    // Se não há agendamentos, retornar periodo inteiro dividido
    if (dataAgendamentos.isEmpty) {
      final inicioMinutos = _timeToMinutes(inicio);
      final fimMinutos = _timeToMinutes(fim);
      final totalMinutos = fimMinutos - inicioMinutos;

      if (totalMinutos >= duracaoMinutos) {
        // Primeiro slot
        slots.add(
          SlotDisponivel(
            inicio: inicio,
            fim: _minutesToTimeOfDay(inicioMinutos + duracaoMinutos),
            possivel: true,
          ),
        );

        // Segundo slot (se houver espaço)
        if (totalMinutos >= duracaoMinutos * 2) {
          slots.add(
            SlotDisponivel(
              inicio: _minutesToTimeOfDay(inicioMinutos + duracaoMinutos),
              fim: fim,
              possivel: totalMinutos - duracaoMinutos >= duracaoMinutos - 30,
            ),
          );
        }
      }
    }

    return slots;
  }

  /// Converter minutos em TimeOfDay
  static TimeOfDay _minutesToTimeOfDay(int minutos) {
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    return TimeOfDay(hour: horas % 24, minute: mins);
  }

  /// Recomendar tipos de serviço disponíveis
  static List<TipoServico> recomendarTipos({
    required List<AgendamentoDiarista> agendamentosExistentes,
    required DateTime data,
  }) {
    final agendamentosConfirmados = agendamentosExistentes
        .where((a) =>
            a.dataAgendamento == data &&
            (a.status == StatusAgendamento.confirmado ||
                a.status == StatusAgendamento.emProgresso))
        .toList();

    // Se não há agendamentos, ambos são possíveis
    if (agendamentosConfirmados.isEmpty) {
      return [TipoServico.meioPeriodo, TipoServico.integral];
    }

    // Se há 1 agendamento de meio período, pode adicionar outro meio período
    if (agendamentosConfirmados.length == 1 &&
        agendamentosConfirmados[0].ehMeioPeriodo) {
      return [TipoServico.meioPeriodo];
    }

    // Se há algo ocupando o dia, não recomenda integral
    return [];
  }
}

/// Resultado de validação
class ValidationResult {
  final bool valido;
  final String mensagem;

  ValidationResult({
    required this.valido,
    required this.mensagem,
  });
}

/// Slot de tempo disponível
class SlotDisponivel {
  final TimeOfDay inicio;
  final TimeOfDay fim;
  final bool possivel;

  SlotDisponivel({
    required this.inicio,
    required this.fim,
    required this.possivel,
  });

  String get horarioFormatado {
    return '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')} - '
        '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
  }
}
