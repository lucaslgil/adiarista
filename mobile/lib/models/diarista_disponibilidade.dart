import 'package:flutter/material.dart';

enum StatusDisponibilidade { bloqueado, meioPeriodo, integral }

extension StatusDisponibilidadeExtension on StatusDisponibilidade {
  String get label {
    switch (this) {
      case StatusDisponibilidade.bloqueado:
        return 'Bloqueado';
      case StatusDisponibilidade.meioPeriodo:
        return 'Meio Período';
      case StatusDisponibilidade.integral:
        return 'Período Integral';
    }
  }

  Color get cor {
    switch (this) {
      case StatusDisponibilidade.bloqueado:
        return Colors.red;
      case StatusDisponibilidade.meioPeriodo:
        return Colors.amber;
      case StatusDisponibilidade.integral:
        return Colors.green;
    }
  }

  String get icon {
    switch (this) {
      case StatusDisponibilidade.bloqueado:
        return '🚫';
      case StatusDisponibilidade.meioPeriodo:
        return '🟡';
      case StatusDisponibilidade.integral:
        return '🟢';
    }
  }
}

class DiaristaDisponibilidade {
  final String id;
  final String diaristaId;
  final DateTime data;
  final StatusDisponibilidade status;
  final TimeOfDay? horaInicio; // override opcional
  final TimeOfDay? horaFim; // override opcional
  final String? notas;

  DiaristaDisponibilidade({
    required this.id,
    required this.diaristaId,
    required this.data,
    required this.status,
    this.horaInicio,
    this.horaFim,
    this.notas,
  });

  // Verificar se é hoje
  bool get ehHoje {
    final hoje = DateTime.now();
    return data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
  }

  // Verificar se é no futuro
  bool get ehNoFuturo {
    return data.isAfter(DateTime.now());
  }

  // Dia da semana em português
  String get diaSemana {
    const dias = [
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sab',
      'Dom',
    ];
    return dias[data.weekday - 1];
  }

  // Formato de data para exibição
  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }

  // Conversor JSON
  factory DiaristaDisponibilidade.fromJson(Map<String, dynamic> json) {
    try {
      return DiaristaDisponibilidade(
        id: json['id'].toString(), // Converte int/string para string
        diaristaId: json['diarista_id'] as String,
        data: DateTime.parse(json['data'] as String),
        status: _parseStatus(json['status'] as String),
        horaInicio: json['hora_inicio'] != null && json['hora_inicio'].toString().isNotEmpty
            ? _parseTimeOfDay(json['hora_inicio'].toString())
            : null,
        horaFim: json['hora_fim'] != null && json['hora_fim'].toString().isNotEmpty
            ? _parseTimeOfDay(json['hora_fim'].toString())
            : null,
        notas: json['notas'] != null ? json['notas'].toString() : null,
      );
    } catch (e) {
      print('❌ [ERROR] Erro ao parsear JSON: $e');
      print('JSON recebido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diarista_id': diaristaId,
      'data': data.toIso8601String().split('T')[0],
      'status': status.name,
      'hora_inicio': horaInicio != null
          ? '${horaInicio!.hour.toString().padLeft(2, '0')}:${horaInicio!.minute.toString().padLeft(2, '0')}'
          : null,
      'hora_fim': horaFim != null
          ? '${horaFim!.hour.toString().padLeft(2, '0')}:${horaFim!.minute.toString().padLeft(2, '0')}'
          : null,
      'notas': notas,
    };
  }

  // Copiar com modificações
  DiaristaDisponibilidade copyWith({
    String? id,
    String? diaristaId,
    DateTime? data,
    StatusDisponibilidade? status,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFim,
    String? notas,
  }) {
    return DiaristaDisponibilidade(
      id: id ?? this.id,
      diaristaId: diaristaId ?? this.diaristaId,
      data: data ?? this.data,
      status: status ?? this.status,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFim: horaFim ?? this.horaFim,
      notas: notas ?? this.notas,
    );
  }
}

// Funções auxiliares
StatusDisponibilidade _parseStatus(String status) {
  return StatusDisponibilidade.values.firstWhere(
    (e) => e.name == status,
    orElse: () => StatusDisponibilidade.bloqueado,
  );
}

TimeOfDay _parseTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}

