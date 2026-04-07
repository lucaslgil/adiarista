/// Modelo para perfil de Diarista
class DiaristaPerfil {
  final String userId;
  final String descricao;
  final double preco; // Preço por diária
  final double avaliacaoMedia;
  final String regiao;
  final List<String> especialidades; // Ex: ['limpeza profunda', 'organização']
  final bool ativo;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  DiaristaPerfil({
    required this.userId,
    required this.descricao,
    required this.preco,
    this.avaliacaoMedia = 0.0,
    required this.regiao,
    this.especialidades = const [],
    this.ativo = true,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory DiaristaPerfil.fromJson(Map<String, dynamic> json) {
    return DiaristaPerfil(
      userId: json['user_id'] as String,
      descricao: json['descricao'] as String,
      preco: (json['preco'] as num).toDouble(),
      avaliacaoMedia: (json['avaliacao_media'] as num?)?.toDouble() ?? 0.0,
      regiao: json['regiao'] as String,
      especialidades: List<String>.from(json['especialidades'] as List? ?? []),
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: json['atualizado_em'] != null 
          ? DateTime.parse(json['atualizado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'descricao': descricao,
      'preco': preco,
      'avaliacao_media': avaliacaoMedia,
      'regiao': regiao,
      'especialidades': especialidades,
      'ativo': ativo,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  DiaristaPerfil copyWith({
    String? userId,
    String? descricao,
    double? preco,
    double? avaliacaoMedia,
    String? regiao,
    List<String>? especialidades,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return DiaristaPerfil(
      userId: userId ?? this.userId,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      avaliacaoMedia: avaliacaoMedia ?? this.avaliacaoMedia,
      regiao: regiao ?? this.regiao,
      especialidades: especialidades ?? this.especialidades,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
