import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/preco_diarista.dart';
import '../models/servico.dart';

/// Serviço para gerenciar a precificação das diaristas.
///
/// Responsável por:
/// - CRUD de [ServicoDiarista] e [PrecoDiarista]
/// - Verificar se a diarista tem preços suficientes para ficar disponível
/// - Calcular estimativas de preço para o cliente
class PrecosService {
  final _supabase = Supabase.instance.client;

  // ─── Serviços Oferecidos ──────────────────────────────────────────────────

  /// Lista os serviços ativos de uma diarista.
  Future<List<ServicoDiarista>> getServicosDiarista(String usuarioId) async {
    try {
      final response = await _supabase
          .from('servicos_diarista')
          .select()
          .eq('usuario_id', usuarioId);

      return (response as List)
          .map((e) => ServicoDiarista.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ativa ou desativa um serviço para a diarista.
  /// Se não existir, cria o registro.
  Future<void> salvarServico({
    required String usuarioId,
    required TipoServico tipo,
    required bool ativo,
  }) async {
    await _supabase.from('servicos_diarista').upsert(
      {
        'usuario_id': usuarioId,
        'tipo_servico': tipo.value,
        'ativo': ativo,
      },
      onConflict: 'usuario_id,tipo_servico',
    );
  }

  // ─── Preços ───────────────────────────────────────────────────────────────

  /// Retorna todos os preços configurados para uma diarista.
  Future<List<PrecoDiarista>> getPrecosDiarista(String usuarioId) async {
    try {
      final response = await _supabase
          .from('precos_diarista')
          .select()
          .eq('usuario_id', usuarioId);

      return (response as List)
          .map((e) => PrecoDiarista.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Salva (cria ou atualiza) a configuração de preços de um serviço.
  Future<void> salvarPrecos({
    required String usuarioId,
    required TipoServico tipo,
    required Map<String, dynamic> configuracao,
    required double valorMinimo,
  }) async {
    await _supabase.from('precos_diarista').upsert(
      {
        'usuario_id': usuarioId,
        'tipo_servico': tipo.value,
        'configuracao': configuracao,
        'valor_minimo': valorMinimo,
      },
      onConflict: 'usuario_id,tipo_servico',
    );
  }

  // ─── Validação de Disponibilidade ─────────────────────────────────────────

  /// Retorna true se a diarista tem ao menos 1 serviço ativo com preços válidos.
  ///
  /// Use antes de permitir que a diarista fique disponível.
  Future<bool> diaristaPodeAtender(String usuarioId) async {
    try {
      final servicos = await getServicosDiarista(usuarioId);
      final ativos = servicos.where((s) => s.ativo).toList();
      if (ativos.isEmpty) return false;

      final precos = await getPrecosDiarista(usuarioId);
      final precosMap = {for (final p in precos) p.tipoServico: p};

      for (final servico in ativos) {
        final preco = precosMap[servico.tipoServico];
        if (preco != null &&
            preco.valorMinimo > 0 &&
            preco.isCompleto) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Cálculo de Estimativa ────────────────────────────────────────────────

  /// Calcula o preço estimado para um pedido do cliente.
  ///
  /// [usuarioDiaristaId] — ID da diarista
  /// [tipo] — tipo de serviço solicitado
  /// [parametrosCliente] — parâmetros preenchidos pelo cliente no formulário
  ///
  /// Retorna null se a diarista não tiver preços configurados.
  Future<double?> calcularEstimativa({
    required String usuarioDiaristaId,
    required TipoServico tipo,
    required Map<String, dynamic> parametrosCliente,
  }) async {
    try {
      final precos = await getPrecosDiarista(usuarioDiaristaId);
      final precosMap = {for (final p in precos) p.tipoServico: p};

      final preco = precosMap[tipo];
      if (preco == null) return null;

      // Para lavarEPassar, precisamos dos configs dos componentes
      final configLavar = precosMap[TipoServico.lavarRoupas];
      final configPassar = precosMap[TipoServico.passarRoupas];

      return CalculadoraPrecos.calcularEstimativa(
        tipo: tipo,
        parametrosCliente: parametrosCliente,
        configuracao: preco.configuracao,
        valorMinimo: preco.valorMinimo,
        configLavar: configLavar?.configuracao,
        valorMinimoLavar: configLavar?.valorMinimo,
        configPassar: configPassar?.configuracao,
        valorMinimoPassar: configPassar?.valorMinimo,
      );
    } catch (_) {
      return null;
    }
  }

  /// Versão síncrona do cálculo quando as configurações já foram carregadas.
  static double? calcularEstimativaLocal({
    required TipoServico tipo,
    required Map<String, dynamic> parametrosCliente,
    required Map<TipoServico, PrecoDiarista> precosMap,
  }) {
    final preco = precosMap[tipo];
    if (preco == null) return null;

    final configLavar = precosMap[TipoServico.lavarRoupas];
    final configPassar = precosMap[TipoServico.passarRoupas];

    return CalculadoraPrecos.calcularEstimativa(
      tipo: tipo,
      parametrosCliente: parametrosCliente,
      configuracao: preco.configuracao,
      valorMinimo: preco.valorMinimo,
      configLavar: configLavar?.configuracao,
      valorMinimoLavar: configLavar?.valorMinimo,
      configPassar: configPassar?.configuracao,
      valorMinimoPassar: configPassar?.valorMinimo,
    );
  }
}
