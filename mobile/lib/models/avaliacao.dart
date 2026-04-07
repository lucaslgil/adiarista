/// Modelo para Avaliação
class Avaliacao {
  final String id;
  final String clienteId;
  final String diaristId;
  final int nota; // 1 a 5 estrelas
  final String? comentario;
  final DateTime criadoEm;

  Avaliacao({
    required this.id,
    required this.clienteId,
    required this.diaristId,
    required this.nota,
    this.comentario,
    required this.criadoEm,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      diaristId: json['diarista_id'] as String,
      nota: json['nota'] as int,
      comentario: json['comentario'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'diarista_id': diaristId,
      'nota': nota,
      'comentario': comentario,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  Avaliacao copyWith({
    String? id,
    String? clienteId,
    String? diaristId,
    int? nota,
    String? comentario,
    DateTime? criadoEm,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      diaristId: diaristId ?? this.diaristId,
      nota: nota ?? this.nota,
      comentario: comentario ?? this.comentario,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
