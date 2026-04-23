class EnderecoCliente {
  final String id;
  final String clienteId;
  final String apelido;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final bool principal;
  final DateTime criadoEm;
  final double? lat;
  final double? lng;

  const EnderecoCliente({
    required this.id,
    required this.clienteId,
    required this.apelido,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    this.principal = false,
    required this.criadoEm,
    this.lat,
    this.lng,
  });

  /// Endereço completo em uma linha (para exibição no formulário)
  String get enderecoCompleto {
    final comp =
        complemento != null && complemento!.isNotEmpty ? ', $complemento' : '';
    return '$logradouro, $numero$comp — $bairro, $cidade/$estado';
  }

  factory EnderecoCliente.fromJson(Map<String, dynamic> json) {
    return EnderecoCliente(
      id: json['id'].toString(),
      clienteId: json['cliente_id'] as String,
      apelido: json['apelido'] as String,
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      estado: json['estado'] as String,
      cep: json['cep'] as String,
      principal: json['principal'] as bool? ?? false,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      lat: (json['latitude'] as num?)?.toDouble(),
      lng: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliente_id': clienteId,
      'apelido': apelido,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'principal': principal,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    };
  }

  EnderecoCliente copyWith({
    String? apelido,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
    bool? principal,
    double? lat,
    double? lng,
  }) {
    return EnderecoCliente(
      id: id,
      clienteId: clienteId,
      apelido: apelido ?? this.apelido,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      principal: principal ?? this.principal,
      criadoEm: criadoEm,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
