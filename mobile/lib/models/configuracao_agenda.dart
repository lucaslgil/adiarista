import 'package:flutter/material.dart';

enum TipoServico { meioPeriodo, integral }

extension TipoServicoExtension on TipoServico {
  String get label {
    switch (this) {
      case TipoServico.meioPeriodo:
        return 'Meio Período (4h)';
      case TipoServico.integral:
        return 'Período Integral (8h)';
    }
  }

  int get duracaoMinutos {
    switch (this) {
      case TipoServico.meioPeriodo:
        return 240; // 4 horas
      case TipoServico.integral:
        return 480; // 8 horas
    }
  }

  String get valor {
    switch (this) {
      case TipoServico.meioPeriodo:
        return '4h';
      case TipoServico.integral:
        return '8h';
    }
  }
}

class ConfiguracaoAgenda {
  final String id;
  final String diaristaId;
  final TimeOfDay horaInicioPadrao; // ex: 08:00
  final TimeOfDay horaFimPadrao; // ex: 18:00
  final int tempoDeslocamentoMinutos; // padrão: 30 min
  /// Dias de trabalho: 0=Dom, 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sab
  final List<int> diasTrabalho;

  ConfiguracaoAgenda({
    required this.id,
    required this.diaristaId,
    required this.horaInicioPadrao,
    required this.horaFimPadrao,
    this.tempoDeslocamentoMinutos = 30,
    List<int>? diasTrabalho,
  }) : diasTrabalho = diasTrabalho ?? const [1, 2, 3, 4, 5];

  // Calcular duração total disponível
  int get duracaoTotalMinutos {
    final inicio = horaInicioPadrao.hour * 60 + horaInicioPadrao.minute;
    final fim = horaFimPadrao.hour * 60 + horaFimPadrao.minute;
    return fim - inicio;
  }

  // Conversor JSON
  factory ConfiguracaoAgenda.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoAgenda(
      id: json['id'] as String,
      diaristaId: json['diarista_id'] as String,
      horaInicioPadrao: _parseTimeOfDay(json['hora_inicio_padrao'] as String),
      horaFimPadrao: _parseTimeOfDay(json['hora_fim_padrao'] as String),
      tempoDeslocamentoMinutos: json['tempo_deslocamento_minutos'] as int? ?? 30,
      diasTrabalho: (json['dias_trabalho'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diarista_id': diaristaId,
      'hora_inicio_padrao': '${horaInicioPadrao.hour.toString().padLeft(2, '0')}:${horaInicioPadrao.minute.toString().padLeft(2, '0')}',
      'hora_fim_padrao': '${horaFimPadrao.hour.toString().padLeft(2, '0')}:${horaFimPadrao.minute.toString().padLeft(2, '0')}',
      'tempo_deslocamento_minutos': tempoDeslocamentoMinutos,
      'dias_trabalho': diasTrabalho,
    };
  }
}

// Função auxiliar para converter string de hora
TimeOfDay _parseTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

