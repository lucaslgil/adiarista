/// Modelo para Solicitação de Serviço
class Solicitacao {
  final String id;
  final String clienteId;
  final String? diaristId; // null enquanto não aceita
  final String status; // 'pendente', 'aceita', 'em_andamento', 'finalizada', 'cancelada'
  final DateTime dataAgendada;
  final String endereco;
  final String descricao;
  final String? observacoes;
  final String? tipoLimpeza; // Valores MVP: 'limpeza_residencial' | 'limpeza_comercial' | 'lavar_roupas' | 'passar_roupas'
  final double? precoEstimado;
  final Map<String, dynamic>? parametros; // Parâmetros específicos do serviço
  final DateTime criadoEm;
  final DateTime? concluidaEm;

  Solicitacao({
    required this.id,
    required this.clienteId,
    this.diaristId,
    this.status = 'pendente',
    required this.dataAgendada,
    required this.endereco,
    required this.descricao,
    this.observacoes,
    this.tipoLimpeza,
    this.precoEstimado,
    this.parametros,
    required this.criadoEm,
    this.concluidaEm,
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      diaristId: json['diarista_id'] as String?,
      status: json['status'] as String? ?? 'pendente',
      dataAgendada: DateTime.parse(json['data_agendada'] as String),
      endereco: json['endereco'] as String,
      descricao: json['descricao'] as String,
      observacoes: json['observacoes'] as String?,
      tipoLimpeza: json['tipo_limpeza'] as String?,
      precoEstimado: (json['preco_estimado'] as num?)?.toDouble(),
      parametros: json['parametros'] != null
          ? Map<String, dynamic>.from(json['parametros'] as Map)
          : null,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      concluidaEm: json['concluida_em'] != null
          ? DateTime.parse(json['concluida_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'diarista_id': diaristId,
      'status': status,
      'data_agendada': dataAgendada.toIso8601String(),
      'endereco': endereco,
      'descricao': descricao,
      'observacoes': observacoes,
      'tipo_limpeza': tipoLimpeza,
      'preco_estimado': precoEstimado,
      'parametros': parametros,
      'criado_em': criadoEm.toIso8601String(),
      'concluida_em': concluidaEm?.toIso8601String(),
    };
  }

  Solicitacao copyWith({
    String? id,
    String? clienteId,
    String? diaristId,
    String? status,
    DateTime? dataAgendada,
    String? endereco,
    String? descricao,
    String? observacoes,
    String? tipoLimpeza,
    double? precoEstimado,
    Map<String, dynamic>? parametros,
    DateTime? criadoEm,
    DateTime? concluidaEm,
  }) {
    return Solicitacao(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      diaristId: diaristId ?? this.diaristId,
      status: status ?? this.status,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      endereco: endereco ?? this.endereco,
      descricao: descricao ?? this.descricao,
      observacoes: observacoes ?? this.observacoes,
      tipoLimpeza: tipoLimpeza ?? this.tipoLimpeza,
      precoEstimado: precoEstimado ?? this.precoEstimado,
      parametros: parametros ?? this.parametros,
      criadoEm: criadoEm ?? this.criadoEm,
      concluidaEm: concluidaEm ?? this.concluidaEm,
    );
  }

  /// Retorna um rótulo legível do status
  String getStatusLabel() {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'aceita':
        return 'Aceita';
      case 'em_andamento':
        return 'Em Andamento';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
