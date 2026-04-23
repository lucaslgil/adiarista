import 'servico.dart';

// ============================================================================
// MODELOS DE PRECIFICAÇÃO
// ============================================================================

/// Representa um serviço que a diarista oferece (ativo ou não).
class ServicoDiarista {
  final String id;
  final String usuarioId;
  final TipoServico tipoServico;
  final bool ativo;
  final DateTime criadoEm;

  const ServicoDiarista({
    required this.id,
    required this.usuarioId,
    required this.tipoServico,
    required this.ativo,
    required this.criadoEm,
  });

  factory ServicoDiarista.fromJson(Map<String, dynamic> json) {
    return ServicoDiarista(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      tipoServico: TipoServico.fromValue(json['tipo_servico'] as String)!,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'tipo_servico': tipoServico.value,
        'ativo': ativo,
      };
}

// ─── Configuração de Preços ───────────────────────────────────────────────────

/// Armazena os preços configurados pela diarista para um tipo de serviço.
///
/// O campo [configuracao] é flexível (JSONB) e varia por tipo:
///
/// **limpeza_residencial**
///   preco_quarto, preco_banheiro, preco_sala, preco_cozinha, taxa_pet (opt)
///
/// **limpeza_comercial**
///   preco_por_m2
///
/// **lavar_roupas**
///   preco_por_hora
///
/// **passar_roupas**
///   modo ("por_hora" | "por_peca"), preco_por_hora ou preco_por_peca,
///   pecas_por_hora (opt, default 20)
///
/// **lavar_e_passar**
///   preco_personalizado (opt — se omitido usa soma lavar+passar)
class PrecoDiarista {
  final String id;
  final String usuarioId;
  final TipoServico tipoServico;
  final Map<String, dynamic> configuracao;
  final double valorMinimo;
  final DateTime criadoEm;

  const PrecoDiarista({
    required this.id,
    required this.usuarioId,
    required this.tipoServico,
    required this.configuracao,
    required this.valorMinimo,
    required this.criadoEm,
  });

  factory PrecoDiarista.fromJson(Map<String, dynamic> json) {
    return PrecoDiarista(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      tipoServico: TipoServico.fromValue(json['tipo_servico'] as String)!,
      configuracao:
          Map<String, dynamic>.from(json['configuracao'] as Map? ?? {}),
      valorMinimo: (json['valor_minimo'] as num).toDouble(),
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
        'tipo_servico': tipoServico.value,
        'configuracao': configuracao,
        'valor_minimo': valorMinimo,
      };

  /// Verifica se todos os campos obrigatórios estão preenchidos.
  bool get isCompleto =>
      CalculadoraPrecos.validarConfiguracao(tipoServico, configuracao);
}

// ─── Calculadora de Preços ────────────────────────────────────────────────────

/// Centraliza toda a lógica de cálculo de estimativas de preço.
///
/// Não tem estado próprio — todos os métodos são estáticos.
class CalculadoraPrecos {
  CalculadoraPrecos._();

  /// Calcula a estimativa de preço com base nos parâmetros do cliente
  /// e na configuração de preços da diarista.
  ///
  /// Garante que o resultado nunca seja menor que [valorMinimo].
  static double? calcularEstimativa({
    required TipoServico tipo,
    required Map<String, dynamic> parametrosCliente,
    required Map<String, dynamic> configuracao,
    required double valorMinimo,
    // Para lavarEPassar, precisamos dos preços dos serviços componentes
    Map<String, dynamic>? configLavar,
    double? valorMinimoLavar,
    Map<String, dynamic>? configPassar,
    double? valorMinimoPassar,
  }) {
    final total = switch (tipo) {
      TipoServico.limpezaResidencial =>
        _calcResidencial(parametrosCliente, configuracao),
      TipoServico.limpezaComercial =>
        _calcComercial(parametrosCliente, configuracao),
      TipoServico.lavarRoupas => _calcLavar(parametrosCliente, configuracao),
      TipoServico.passarRoupas => _calcPassar(parametrosCliente, configuracao),
      TipoServico.lavarEPassar => _calcLavarEPassar(
          parametrosCliente,
          configuracao,
          configLavar: configLavar,
          valorMinimoLavar: valorMinimoLavar,
          configPassar: configPassar,
          valorMinimoPassar: valorMinimoPassar,
        ),
    };
    if (total == null) return null;
    return total < valorMinimo ? valorMinimo : total;
  }

  // ── Limpeza Residencial ────────────────────────────────────────────────────
  // Fórmula: soma dos cômodos por preço unitário + taxa_pet (se pets)
  static double? _calcResidencial(
    Map<String, dynamic> params,
    Map<String, dynamic> config,
  ) {
    final precoQuarto = (config['preco_quarto'] as num?)?.toDouble();
    final precoBanheiro = (config['preco_banheiro'] as num?)?.toDouble();
    final precoSala = (config['preco_sala'] as num?)?.toDouble();
    final precoCozinha = (config['preco_cozinha'] as num?)?.toDouble();

    if (precoQuarto == null ||
        precoBanheiro == null ||
        precoSala == null ||
        precoCozinha == null) return null;

    final qtdQuartos = (params['qtd_quartos'] as int?) ?? 1;
    final qtdBanheiros = (params['qtd_banheiros'] as int?) ?? 1;
    final qtdSalas = (params['qtd_salas'] as int?) ?? 1;
    final qtdCozinhas = (params['qtd_cozinhas'] as int?) ?? 1;
    final qtdLavanderia = (params['qtd_lavanderia'] as int?) ?? 0;
    final qtdGaragem = (params['qtd_garagem'] as int?) ?? 0;
    final qtdGourmet = (params['qtd_gourmet'] as int?) ?? 0;
    final qtdEscritorio = (params['qtd_escritorio'] as int?) ?? 0;

    final precoLavanderia =
        (config['preco_lavanderia'] as num?)?.toDouble() ?? 0.0;
    final precoGaragem = (config['preco_garagem'] as num?)?.toDouble() ?? 0.0;
    final precoGourmet = (config['preco_gourmet'] as num?)?.toDouble() ?? 0.0;
    final precoEscritorio =
        (config['preco_escritorio'] as num?)?.toDouble() ?? 0.0;

    double total = (qtdQuartos * precoQuarto) +
        (qtdBanheiros * precoBanheiro) +
        (qtdSalas * precoSala) +
        (qtdCozinhas * precoCozinha) +
        (qtdLavanderia * precoLavanderia) +
        (qtdGaragem * precoGaragem) +
        (qtdGourmet * precoGourmet) +
        (qtdEscritorio * precoEscritorio);

    // Taxa pet
    final temPet = params['possuiPets'] as bool? ?? false;
    if (temPet) {
      final taxaPet = (config['taxa_pet'] as num?)?.toDouble() ?? 0.0;
      total += taxaPet;
    }

    return total;
  }

  // ── Limpeza Comercial ──────────────────────────────────────────────────────
  // Fórmula: metragem * preco_por_m2 * multiplicador_sujeira
  static double? _calcComercial(
    Map<String, dynamic> params,
    Map<String, dynamic> config,
  ) {
    final precoPorM2 = (config['preco_por_m2'] as num?)?.toDouble();
    if (precoPorM2 == null) return null;

    final metragem = (params['metragem'] as num?)?.toDouble();
    if (metragem == null || metragem <= 0) return null;

    double total = metragem * precoPorM2;

    return total;
  }

  // ── Lavar Roupas ───────────────────────────────────────────────────────────
  // Fórmula: horas_estimadas * preco_por_hora
  // tamanho → horas: pequeno=1h, medio=2h, grande=3h
  static double? _calcLavar(
    Map<String, dynamic> params,
    Map<String, dynamic> config,
  ) {
    final precoPorHora = (config['preco_por_hora'] as num?)?.toDouble();
    if (precoPorHora == null) return null;

    final tamanho = params['tamanho'] as String?;
    final horas = switch (tamanho) {
      'pequeno' => 1.0,
      'medio' => 2.0,
      'grande' => 3.0,
      _ => null,
    };
    if (horas == null) return null;

    return horas * precoPorHora;
  }

  // ── Passar Roupas ──────────────────────────────────────────────────────────
  // Modo por_peca: qtdPecas * preco_por_peca
  // Modo por_hora: ceil(qtdPecas / pecas_por_hora) * preco_por_hora
  static double? _calcPassar(
    Map<String, dynamic> params,
    Map<String, dynamic> config,
  ) {
    final modo = config['modo'] as String? ?? 'por_peca';
    final qtdPecas = (params['quantidadePecas'] as int?) ?? 0;

    if (modo == 'por_peca') {
      final precoPorPeca = (config['preco_por_peca'] as num?)?.toDouble();
      if (precoPorPeca == null) return null;
      return qtdPecas * precoPorPeca;
    } else {
      // por_hora
      final precoPorHora = (config['preco_por_hora'] as num?)?.toDouble();
      if (precoPorHora == null) return null;
      final pecasPorHora = (config['pecas_por_hora'] as num?)?.toDouble() ?? 20;
      final horas = (qtdPecas / pecasPorHora).ceil();
      return horas * precoPorHora;
    }
  }

  // ── Lavar + Passar ─────────────────────────────────────────────────────────
  // Usa preco_personalizado se definido, senão soma lavar + passar
  static double? _calcLavarEPassar(
    Map<String, dynamic> params,
    Map<String, dynamic> config, {
    Map<String, dynamic>? configLavar,
    double? valorMinimoLavar,
    Map<String, dynamic>? configPassar,
    double? valorMinimoPassar,
  }) {
    final precoPersonalizado =
        (config['preco_personalizado'] as num?)?.toDouble();
    if (precoPersonalizado != null && precoPersonalizado > 0) {
      return precoPersonalizado;
    }

    // Soma dos dois serviços componentes
    if (configLavar == null || configPassar == null) return null;

    final totalLavar = _calcLavar(params, configLavar);
    final totalPassar = _calcPassar(params, configPassar);

    if (totalLavar == null && totalPassar == null) return null;

    double soma = 0;
    if (totalLavar != null) {
      soma += totalLavar < (valorMinimoLavar ?? 0)
          ? (valorMinimoLavar ?? 0)
          : totalLavar;
    }
    if (totalPassar != null) {
      soma += totalPassar < (valorMinimoPassar ?? 0)
          ? (valorMinimoPassar ?? 0)
          : totalPassar;
    }
    return soma;
  }

  // ─── Validação de Configuração ────────────────────────────────────────────

  /// Retorna true se a configuração de preços está completa para o tipo.
  static bool validarConfiguracao(
    TipoServico tipo,
    Map<String, dynamic> config,
  ) {
    double? _v(String key) => (config[key] as num?)?.toDouble();

    return switch (tipo) {
      TipoServico.limpezaResidencial => _v('preco_quarto') != null &&
          _v('preco_banheiro') != null &&
          _v('preco_sala') != null &&
          _v('preco_cozinha') != null,
      TipoServico.limpezaComercial => _v('preco_por_m2') != null,
      TipoServico.lavarRoupas => _v('preco_por_hora') != null,
      TipoServico.passarRoupas => (config['modo'] == 'por_hora'
          ? _v('preco_por_hora') != null
          : _v('preco_por_peca') != null),
      TipoServico.lavarEPassar =>
        true, // preco_personalizado é opcional; sem ele usa componentes
    };
  }

  /// Retorna mensagem de campo faltante ou null se completo.
  static String? mensagemCampoFaltante(
    TipoServico tipo,
    Map<String, dynamic> config,
  ) {
    if (validarConfiguracao(tipo, config)) return null;
    return switch (tipo) {
      TipoServico.limpezaResidencial => 'Preencha todos os preços por cômodo',
      TipoServico.limpezaComercial => 'Informe o preço por m²',
      TipoServico.lavarRoupas => 'Informe o preço por hora',
      TipoServico.passarRoupas => 'Informe o preço de cobrança',
      TipoServico.lavarEPassar => null,
    };
  }
}
// ============================================================================
// DURAÇÃO DE SERVIÇOS
// ============================================================================

/// Calcula a duração estimada de um serviço em minutos.
///
/// Utilizado tanto para exibição ao cliente quanto para geração de horários
/// disponíveis e validação de overbooking.
class DuracaoServico {
  // Minutos por tipo de cômodo
  static const _minPorQuarto = 40;
  static const _minPorBanheiro = 50;
  static const _minPorSala = 30;
  static const _minPorCozinha = 60;

  /// Retorna a duração estimada em minutos para o serviço + parâmetros dados.
  static int calcularMinutos(
    TipoServico tipo,
    Map<String, dynamic> params,
  ) {
    int _i(String key, [int def = 1]) => (params[key] as num?)?.toInt() ?? def;

    switch (tipo) {
      case TipoServico.limpezaResidencial:
        final quartos = _i('qtd_quartos');
        final banheiros = _i('qtd_banheiros');
        final salas = _i('qtd_salas');
        final cozinhas = _i('qtd_cozinhas');
        final lavanderia = _i('qtd_lavanderia', 0);
        final garagem = _i('qtd_garagem', 0);
        final gourmet = _i('qtd_gourmet', 0);
        final escritorio = _i('qtd_escritorio', 0);
        return quartos * _minPorQuarto +
            banheiros * _minPorBanheiro +
            salas * _minPorSala +
            cozinhas * _minPorCozinha +
            lavanderia * 30 +
            garagem * 25 +
            gourmet * 40 +
            escritorio * 30;

      case TipoServico.limpezaComercial:
        final m2 = _i('metragem', 50);
        // ~60 min por cada 50 m²
        return ((m2 / 50).ceil() * 60).clamp(60, 480);

      case TipoServico.lavarRoupas:
        final tamanho = params['tamanho'] as String? ?? 'media';
        return switch (tamanho) {
          'pequena' => 60,
          'grande' => 180,
          _ => 120,
        };

      case TipoServico.passarRoupas:
        final pecas = (params['quantidadePecas'] as num?)?.toInt() ?? 0;
        if (pecas > 0) return (pecas * 3).clamp(30, 180);
        return 60;

      case TipoServico.lavarEPassar:
        final tamanho = params['tamanho'] as String? ?? 'media';
        final lavar = switch (tamanho) {
          'pequena' => 60,
          'grande' => 180,
          _ => 120,
        };
        final pecas = (params['quantidadePecas'] as num?)?.toInt() ?? 0;
        final passar = pecas > 0 ? (pecas * 3).clamp(30, 120) : 60;
        return lavar + passar;
    }
  }

  /// Formata duração em minutos como string legível (ex: "2h 30min").
  static String formatar(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
