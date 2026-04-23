/// Modelo para perfil de Diarista
class DiaristaPerfil {
  final String userId;
  final String nome;
  final String descricao;
  final double preco; // Preço por diária
  final double avaliacaoMedia;
  final String regiao;
  final List<String> especialidades; // Ex: ['limpeza profunda', 'organização']
  final bool ativo;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final double? lat;
  final double? lng;
  final List<String> cidadesAtendidas;
  final bool limitarPorRaio;
  final double raioKm;

  DiaristaPerfil({
    required this.userId,
    this.nome = '',
    required this.descricao,
    required this.preco,
    this.avaliacaoMedia = 0.0,
    required this.regiao,
    this.especialidades = const [],
    this.ativo = true,
    required this.criadoEm,
    this.atualizadoEm,
    this.lat,
    this.lng,
    this.cidadesAtendidas = const [],
    this.limitarPorRaio = false,
    this.raioKm = 20.0,
  });

  factory DiaristaPerfil.fromJson(Map<String, dynamic> json) {
    // Suporta tanto query simples quanto join com users (users!inner(nome))
    String nome = '';
    final usersData = json['users'];
    if (usersData is Map<String, dynamic>) {
      nome = usersData['nome'] as String? ?? '';
    }
    return DiaristaPerfil(
      userId: json['user_id'] as String,
      nome: nome,
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
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
      cidadesAtendidas:
          List<String>.from(json['cidades_atendidas'] as List? ?? []),
      limitarPorRaio: json['limitar_por_raio'] as bool? ?? false,
      raioKm: (json['raio_km'] as num?)?.toDouble() ?? 20.0,
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
    String? nome,
    String? descricao,
    double? preco,
    double? avaliacaoMedia,
    String? regiao,
    List<String>? especialidades,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    double? lat,
    double? lng,
    List<String>? cidadesAtendidas,
    bool? limitarPorRaio,
    double? raioKm,
  }) {
    return DiaristaPerfil(
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      avaliacaoMedia: avaliacaoMedia ?? this.avaliacaoMedia,
      regiao: regiao ?? this.regiao,
      especialidades: especialidades ?? this.especialidades,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      cidadesAtendidas: cidadesAtendidas ?? this.cidadesAtendidas,
      limitarPorRaio: limitarPorRaio ?? this.limitarPorRaio,
      raioKm: raioKm ?? this.raioKm,
    );
  }
}
