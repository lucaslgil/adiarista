import 'package:flutter/material.dart';
import 'configuracao_agenda.dart';

enum StatusAgendamento { pendente, confirmado, emProgresso, finalizado, cancelado }

extension StatusAgendamentoExtension on StatusAgendamento {
  String get label {
    switch (this) {
      case StatusAgendamento.pendente:
        return 'Pendente';
      case StatusAgendamento.confirmado:
        return 'Confirmado';
      case StatusAgendamento.emProgresso:
        return 'Em Andamento';
      case StatusAgendamento.finalizado:
        return 'Finalizado';
      case StatusAgendamento.cancelado:
        return 'Cancelado';
    }
  }

  Color get cor {
    switch (this) {
      case StatusAgendamento.pendente:
        return Colors.orange;
      case StatusAgendamento.confirmado:
        return Colors.blue;
      case StatusAgendamento.emProgresso:
        return Colors.green;
      case StatusAgendamento.finalizado:
        return Colors.grey;
      case StatusAgendamento.cancelado:
        return Colors.red;
    }
  }

  String get icon {
    switch (this) {
      case StatusAgendamento.pendente:
        return '⏳';
      case StatusAgendamento.confirmado:
        return '✅';
      case StatusAgendamento.emProgresso:
        return '🔄';
      case StatusAgendamento.finalizado:
        return '✔️';
      case StatusAgendamento.cancelado:
        return '❌';
    }
  }
}

class AgendamentoDiarista {
  final String id;
  final String diaristaId;
  final String clienteId;
  final DateTime dataAgendamento;
  final TimeOfDay horarioInicio;
  final TimeOfDay horarioFim;
  final TipoServico tipoServico;
  final StatusAgendamento status;
  final String endereco;
  final String? observacoes;
  final double? valorAcordado;

  AgendamentoDiarista({
    required this.id,
    required this.diaristaId,
    required this.clienteId,
    required this.dataAgendamento,
    required this.horarioInicio,
    required this.horarioFim,
    required this.tipoServico,
    required this.status,
    required this.endereco,
    this.observacoes,
    this.valorAcordado,
  });

  // Duração em minutos
  int get duracaoMinutos {
    final inicio = horarioInicio.hour * 60 + horarioInicio.minute;
    final fim = horarioFim.hour * 60 + horarioFim.minute;
    return fim - inicio;
  }

  // Verificar se é meio período ou integral
  bool get ehMeioPeriodo => tipoServico == TipoServico.meioPeriodo;
  bool get ehIntegral => tipoServico == TipoServico.integral;

  // Data formatada
  String get dataFormatada {
    return '${dataAgendamento.day.toString().padLeft(2, '0')}/${dataAgendamento.month.toString().padLeft(2, '0')}/${dataAgendamento.year}';
  }

  // Hora formatada
  String get horarioFormatado {
    return '${horarioInicio.hour.toString().padLeft(2, '0')}:${horarioInicio.minute.toString().padLeft(2, '0')} - '
        '${horarioFim.hour.toString().padLeft(2, '0')}:${horarioFim.minute.toString().padLeft(2, '0')}';
  }

  // Verificar se é hoje
  bool get ehHoje {
    final hoje = DateTime.now();
    return dataAgendamento.year == hoje.year &&
        dataAgendamento.month == hoje.month &&
        dataAgendamento.day == hoje.day;
  }

  // Verificar se é no futuro
  bool get ehNoFuturo {
    return dataAgendamento.isAfter(DateTime.now());
  }

  // Conversor JSON
  factory AgendamentoDiarista.fromJson(Map<String, dynamic> json) {
    return AgendamentoDiarista(
      id: json['id'] as String,
      diaristaId: json['diarista_id'] as String,
      clienteId: json['cliente_id'] as String,
      dataAgendamento: DateTime.parse(json['data_agendamento'] as String),
      horarioInicio: _parseTimeOfDay(json['horario_inicio'] as String),
      horarioFim: _parseTimeOfDay(json['horario_fim'] as String),
      tipoServico: _parseTipoServico(json['tipo_servico'] as String),
      status: _parseStatus(json['status'] as String),
      endereco: json['endereco'] as String,
      observacoes: json['observacoes'] as String?,
      valorAcordado: json['valor_acordado'] != null
          ? double.parse(json['valor_acordado'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diarista_id': diaristaId,
      'cliente_id': clienteId,
      'data_agendamento': dataAgendamento.toIso8601String().split('T')[0],
      'horario_inicio': '${horarioInicio.hour.toString().padLeft(2, '0')}:${horarioInicio.minute.toString().padLeft(2, '0')}',
      'horario_fim': '${horarioFim.hour.toString().padLeft(2, '0')}:${horarioFim.minute.toString().padLeft(2, '0')}',
      'tipo_servico': tipoServico.name,
      'status': status.name,
      'endereco': endereco,
      'observacoes': observacoes,
      'valor_acordado': valorAcordado,
    };
  }

  // Copiar com modificações
  AgendamentoDiarista copyWith({
    String? id,
    String? diaristaId,
    String? clienteId,
    DateTime? dataAgendamento,
    TimeOfDay? horarioInicio,
    TimeOfDay? horarioFim,
    TipoServico? tipoServico,
    StatusAgendamento? status,
    String? endereco,
    String? observacoes,
    double? valorAcordado,
  }) {
    return AgendamentoDiarista(
      id: id ?? this.id,
      diaristaId: diaristaId ?? this.diaristaId,
      clienteId: clienteId ?? this.clienteId,
      dataAgendamento: dataAgendamento ?? this.dataAgendamento,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      tipoServico: tipoServico ?? this.tipoServico,
      status: status ?? this.status,
      endereco: endereco ?? this.endereco,
      observacoes: observacoes ?? this.observacoes,
      valorAcordado: valorAcordado ?? this.valorAcordado,
    );
  }
}

// Funções auxiliares
TipoServico _parseTipoServico(String tipo) {
  return TipoServico.values.firstWhere(
    (e) => e.name == tipo,
    orElse: () => TipoServico.meioPeriodo,
  );
}

StatusAgendamento _parseStatus(String status) {
  return StatusAgendamento.values.firstWhere(
    (e) => e.name == status,
    orElse: () => StatusAgendamento.pendente,
  );
}

TimeOfDay _parseTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

