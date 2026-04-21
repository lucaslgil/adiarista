/// Tipos de recorrência disponíveis para bloqueio de agenda
enum TipoRecorrencia { semanal, mensal }

extension TipoRecorrenciaExtension on TipoRecorrencia {
  String get label {
    switch (this) {
      case TipoRecorrencia.semanal:
        return 'Toda semana';
      case TipoRecorrencia.mensal:
        return 'Todo mês';
    }
  }

  String get descricao {
    switch (this) {
      case TipoRecorrencia.semanal:
        return 'Repete no mesmo dia da semana';
      case TipoRecorrencia.mensal:
        return 'Repete no mesmo dia do mês';
    }
  }

  String get name {
    switch (this) {
      case TipoRecorrencia.semanal:
        return 'semanal';
      case TipoRecorrencia.mensal:
        return 'mensal';
    }
  }
}

/// Modelo de regra de bloqueio recorrente da diarista.
/// Não gera registros futuros — a lógica é avaliada dinamicamente.
class BloqueioRecorrente {
  final String id;
  final String diaristaId;

  /// semanal ou mensal
  final TipoRecorrencia tipo;

  /// Para semanal: 0=Dom, 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sab
  /// Para mensal: 1–31 (dia do mês)
  final int valor;

  /// A partir de quando a regra vale
  final DateTime dataInicio;

  /// Até quando (null = sem fim)
  final DateTime? dataFim;

  /// Regra ativa ou desativada
  final bool ativo;

  const BloqueioRecorrente({
    required this.id,
    required this.diaristaId,
    required this.tipo,
    required this.valor,
    required this.dataInicio,
    this.dataFim,
    this.ativo = true,
  });

  factory BloqueioRecorrente.fromJson(Map<String, dynamic> json) {
    return BloqueioRecorrente(
      id: json['id'].toString(),
      diaristaId: json['diarista_id'] as String,
      tipo: json['tipo'] == 'mensal'
          ? TipoRecorrencia.mensal
          : TipoRecorrencia.semanal,
      valor: json['valor'] as int,
      dataInicio: DateTime.parse(json['data_inicio'] as String),
      dataFim: json['data_fim'] != null
          ? DateTime.parse(json['data_fim'] as String)
          : null,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diarista_id': diaristaId,
      'tipo': tipo.name,
      'valor': valor,
      'data_inicio': dataInicio.toIso8601String().split('T')[0],
      'data_fim': dataFim?.toIso8601String().split('T')[0],
      'ativo': ativo,
    };
  }

  /// Verifica se esta regra se aplica à data informada
  bool aplicaNaData(DateTime data) {
    if (!ativo) return false;
    // Antes da data de início → não aplica
    final inicio =
        DateTime(dataInicio.year, dataInicio.month, dataInicio.day);
    final alvo = DateTime(data.year, data.month, data.day);
    if (alvo.isBefore(inicio)) return false;

    // Depois da data de fim → não aplica
    if (dataFim != null) {
      final fim = DateTime(dataFim!.year, dataFim!.month, dataFim!.day);
      if (alvo.isAfter(fim)) return false;
    }

    if (tipo == TipoRecorrencia.semanal) {
      // Dart: weekday 1=Seg...7=Dom; nossa convenção 0=Dom,1=Seg...6=Sab
      final diaSemana = data.weekday % 7; // 0=Dom...6=Sab
      return diaSemana == valor;
    } else {
      return data.day == valor;
    }
  }

  /// Nome do dia da semana (para tipo semanal)
  String get labelDiaSemana {
    const dias = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
    if (tipo == TipoRecorrencia.semanal && valor >= 0 && valor <= 6) {
      return dias[valor];
    }
    return '';
  }
}
