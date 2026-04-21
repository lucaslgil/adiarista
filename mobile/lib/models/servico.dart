import 'package:flutter/material.dart';

// ============================================================================
// TIPOS DE SERVIÇO — MVP
// ============================================================================
// Para adicionar um novo serviço:
//   1. Adicione o valor no enum TipoServico
//   2. Adicione a ServicoConfig correspondente em ServicoRegistry._configs
//   3. Implemente _validar<NomeServico> e _build<NomeServico>Parametros
// ============================================================================

enum TipoServico {
  limpezaResidencial('limpeza_residencial'),
  limpezaComercial('limpeza_comercial'),
  lavarRoupas('lavar_roupas'),
  passarRoupas('passar_roupas'),
  lavarEPassar('lavar_e_passar');

  final String value;
  const TipoServico(this.value);

  static TipoServico? fromValue(String? v) {
    if (v == null) return null;
    for (final t in TipoServico.values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

// ─── Unidades de Cobrança ────────────────────────────────────────────────────

enum UnidadeCobranca {
  porServico('por serviço'),
  porM2('por m²'),
  porLote('por lote'),
  porPeca('por peça');

  final String label;
  const UnidadeCobranca(this.label);
}

// ─── Configuração de Serviço ─────────────────────────────────────────────────

class ServicoConfig {
  final TipoServico tipo;
  final String label;
  final IconData icon;
  final UnidadeCobranca unidade;
  final List<String> parametrosObrigatorios;
  final List<String> parametrosOpcionais;

  const ServicoConfig({
    required this.tipo,
    required this.label,
    required this.icon,
    required this.unidade,
    required this.parametrosObrigatorios,
    this.parametrosOpcionais = const [],
  });

  /// Valida os parâmetros. Retorna mensagem de erro ou null se válido.
  String? validarParametros(Map<String, dynamic> params) {
    return switch (tipo) {
      TipoServico.limpezaResidencial =>
        ServicoValidators.limpezaResidencial(params),
      TipoServico.limpezaComercial =>
        ServicoValidators.limpezaComercial(params),
      TipoServico.lavarRoupas => ServicoValidators.lavarRoupas(params),
      TipoServico.passarRoupas => ServicoValidators.passarRoupas(params),
      TipoServico.lavarEPassar => ServicoValidators.lavarEPassar(params),
    };
  }
}

// ─── Validadores por Serviço ─────────────────────────────────────────────────

class ServicoValidators {
  ServicoValidators._();

  static String? limpezaResidencial(Map<String, dynamic> p) {
    final comodos = p['quantidadeComodos'] as int?;
    if (comodos == null || comodos < 1) {
      return 'Informe a quantidade de cômodos';
    }
    final nivel = p['nivelSujeira'] as String?;
    const niveisValidos = ['leve', 'medio', 'pesado'];
    if (nivel == null || !niveisValidos.contains(nivel)) {
      return 'Selecione o nível de sujeira';
    }
    return null;
  }

  static String? limpezaComercial(Map<String, dynamic> p) {
    final metragem = p['metragem'];
    final valor = metragem is num ? metragem.toDouble() : null;
    if (valor == null || valor <= 0) {
      return 'Informe a metragem do local';
    }
    return null;
  }

  static String? lavarRoupas(Map<String, dynamic> p) {
    final tamanho = p['tamanho'] as String?;
    const tamanhoValidos = ['pequeno', 'medio', 'grande'];
    if (tamanho == null || !tamanhoValidos.contains(tamanho)) {
      return 'Selecione o tamanho do lote';
    }
    return null;
  }

  static String? passarRoupas(Map<String, dynamic> p) {
    final pecas = p['quantidadePecas'] as int?;
    if (pecas == null || pecas < 1) {
      return 'Informe a quantidade de peças';
    }
    return null;
  }

  /// Lavar + Passar exige pelo menos o tamanho do lote (componente lavar)
  static String? lavarEPassar(Map<String, dynamic> p) {
    return lavarRoupas(p);
  }
}

// ─── Registry Central ────────────────────────────────────────────────────────

class ServicoRegistry {
  ServicoRegistry._();

  static const Map<TipoServico, ServicoConfig> _configs = {
    TipoServico.limpezaResidencial: ServicoConfig(
      tipo: TipoServico.limpezaResidencial,
      label: 'Limpeza Residencial',
      icon: Icons.home_outlined,
      unidade: UnidadeCobranca.porServico,
      parametrosObrigatorios: ['quantidadeComodos', 'nivelSujeira'],
      parametrosOpcionais: ['possuiPets'],
    ),
    TipoServico.limpezaComercial: ServicoConfig(
      tipo: TipoServico.limpezaComercial,
      label: 'Limpeza Comercial',
      icon: Icons.business_outlined,
      unidade: UnidadeCobranca.porM2,
      parametrosObrigatorios: ['metragem'],
    ),
    TipoServico.lavarRoupas: ServicoConfig(
      tipo: TipoServico.lavarRoupas,
      label: 'Lavar Roupas',
      icon: Icons.local_laundry_service_outlined,
      unidade: UnidadeCobranca.porLote,
      parametrosObrigatorios: ['tamanho'],
    ),
    TipoServico.passarRoupas: ServicoConfig(
      tipo: TipoServico.passarRoupas,
      label: 'Passar Roupas',
      icon: Icons.iron_outlined,
      unidade: UnidadeCobranca.porPeca,
      parametrosObrigatorios: ['quantidadePecas'],
    ),
    TipoServico.lavarEPassar: ServicoConfig(
      tipo: TipoServico.lavarEPassar,
      label: 'Lavar + Passar',
      icon: Icons.dry_cleaning_outlined,
      unidade: UnidadeCobranca.porServico,
      parametrosObrigatorios: ['tamanho'],
      parametrosOpcionais: ['quantidadePecas'],
    ),
  };

  /// Retorna a config de um serviço.
  static ServicoConfig get(TipoServico tipo) => _configs[tipo]!;

  /// Todos os serviços disponíveis no MVP.
  static List<ServicoConfig> get all =>
      TipoServico.values.map((t) => _configs[t]!).toList();

  /// Retorna o label legível a partir do valor string (compatível com dados antigos).
  static String labelFor(String? value) {
    final tipo = TipoServico.fromValue(value);
    if (tipo != null) return _configs[tipo]!.label;
    // Fallback para registros antigos com valor livre
    return value ?? 'Serviço de limpeza';
  }
}
