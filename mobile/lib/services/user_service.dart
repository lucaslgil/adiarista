import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/diarista_perfil.dart';
import '../models/solicitacao.dart';
import '../models/avaliacao.dart';

/// Serviço para gerenciar dados dos usuários
class UserService {
  final _supabase = Supabase.instance.client;

  /// Obter dados do usuário pelo ID
  Future<models.User?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return models.User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  /// Obter usuário atual
  Future<models.User?> getCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return getUserById(userId);
  }

  /// Atualizar dados do usuário
  Future<void> updateUser({
    required String userId,
    String? nome,
    String? fotoPerfil,
  }) async {
    try {
      final updates = <String, dynamic>{
        'atualizado_em': DateTime.now().toIso8601String(),
      };

      if (nome != null) updates['nome'] = nome;
      if (fotoPerfil != null) updates['foto_perfil'] = fotoPerfil;

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  // ============== DIARISTA OPERATIONS ==============

  /// Obter perfil da diarista
  Future<DiaristaPerfil?> getDiaristaPerfil(String userId) async {
    try {
      final response = await _supabase
          .from('diaristas')
          .select()
          .eq('user_id', userId)
          .single();

      return DiaristaPerfil.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao buscar perfil da diarista: $e');
    }
  }

  /// Atualizar perfil da diarista
  Future<void> updateDiaristaPerfil({
    required String userId,
    String? descricao,
    double? preco,
    String? regiao,
    List<String>? especialidades,
    bool? ativo,
  }) async {
    try {
      final updates = <String, dynamic>{
        'atualizado_em': DateTime.now().toIso8601String(),
      };

      if (descricao != null) updates['descricao'] = descricao;
      if (preco != null) updates['preco'] = preco;
      if (regiao != null) updates['regiao'] = regiao;
      if (especialidades != null) updates['especialidades'] = especialidades;
      if (ativo != null) updates['ativo'] = ativo;

      await _supabase
          .from('diaristas')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Erro ao atualizar perfil da diarista: $e');
    }
  }

  /// Listar diaristas disponíveis filtradas por região
  Future<List<DiaristaPerfil>> getDiaristasDisponiveis({
    String regiao = '',
    double? precoMinimo,
    double? precoMaximo,
    double? avaliacaoMinima,
  }) async {
    try {
      var query = _supabase
          .from('diaristas')
          .select()
          .eq('ativo', true);

      if (regiao.isNotEmpty) {
        query = query.eq('regiao', regiao);
      }

      if (precoMinimo != null) {
        query = query.gte('preco', precoMinimo);
      }
      if (precoMaximo != null) {
        query = query.lte('preco', precoMaximo);
      }
      if (avaliacaoMinima != null) {
        query = query.gte('avaliacao_media', avaliacaoMinima);
      }

      final response = await query;

      return (response as List)
          .map((e) => DiaristaPerfil.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar diaristas: $e');
    }
  }

  // ============== SOLICITAÇÃO OPERATIONS ==============

  /// Criar nova solicitação de serviço
  Future<String> criarSolicitacao({
    required String clienteId,
    required DateTime dataAgendada,
    required String endereco,
    required String descricao,
    String? observacoes,
    String? tipoLimpeza,
    Map<String, dynamic>? parametros,
    double? precoEstimado,
  }) async {
    try {
      final response = await _supabase.from('solicitacoes').insert({
        'cliente_id': clienteId,
        'status': 'pendente',
        'data_agendada': dataAgendada.toIso8601String(),
        'endereco': endereco,
        'descricao': descricao,
        'observacoes': observacoes,
        'tipo_limpeza': tipoLimpeza,
        'parametros': parametros,
        'preco_estimado': precoEstimado,
        'criado_em': DateTime.now().toIso8601String(),
      }).select('id');

      return response.first['id'] as String;
    } catch (e) {
      throw Exception('Erro ao criar solicitação: $e');
    }
  }

  /// Obter solicitação pelo ID
  Future<Solicitacao?> getSolicitacaoById(String solicitacaoId) async {
    try {
      final response = await _supabase
          .from('solicitacoes')
          .select()
          .eq('id', solicitacaoId)
          .single();

      return Solicitacao.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao buscar solicitação: $e');
    }
  }

  /// Obter solicitações pendentes para uma diarista (por região)
  Future<List<Solicitacao>> getSolicitacoesPendentes(String regiao) async {
    try {
      final response = await _supabase
          .from('solicitacoes')
          .select()
          .eq('status', 'pendente')
          .order('data_agendada', ascending: true);

      return (response as List)
          .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações pendentes: $e');
    }
  }

  /// Obter solicitações do cliente
  Future<List<Solicitacao>> getSolicitacoesCliente(String clienteId) async {
    try {
      final response = await _supabase
          .from('solicitacoes')
          .select()
          .eq('cliente_id', clienteId)
          .order('data_agendada', ascending: false);

      return (response as List)
          .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações do cliente: $e');
    }
  }

  /// Obter solicitações aceitas pela diarista
  Future<List<Solicitacao>> getSolicitacoesDiarista(String diaristId) async {
    try {
      final response = await _supabase
          .from('solicitacoes')
          .select()
          .eq('diarista_id', diaristId)
          .order('data_agendada', ascending: true);

      return (response as List)
          .map((e) => Solicitacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações da diarista: $e');
    }
  }

  /// Aceitar solicitação como diarista
  Future<void> aceitarSolicitacao({
    required String solicitacaoId,
    required String diaristId,
  }) async {
    try {
      await _supabase
          .from('solicitacoes')
          .update({
            'diarista_id': diaristId,
            'status': 'aceita',
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('id', solicitacaoId);
    } catch (e) {
      throw Exception('Erro ao aceitar solicitação: $e');
    }
  }

  /// Recusar solicitação
  Future<void> recusarSolicitacao(String solicitacaoId) async {
    try {
      await _supabase
          .from('solicitacoes')
          .update({
            'diarista_id': null,
            'status': 'pendente',
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('id', solicitacaoId);
    } catch (e) {
      throw Exception('Erro ao recusar solicitação: $e');
    }
  }

  /// Atualizar status da solicitação
  Future<void> atualizarStatusSolicitacao({
    required String solicitacaoId,
    required String novoStatus,
  }) async {
    try {
      await _supabase
          .from('solicitacoes')
          .update({
            'status': novoStatus,
            'concluida_em': novoStatus == 'finalizada'
                ? DateTime.now().toIso8601String()
                : null,
            'atualizado_em': DateTime.now().toIso8601String(),
          })
          .eq('id', solicitacaoId);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  // ============== AVALIAÇÃO OPERATIONS ==============

  /// Criar avaliação
  Future<void> criarAvaliacao({
    required String clienteId,
    required String diaristId,
    required int nota,
    String? comentario,
  }) async {
    try {
      await _supabase.from('avaliacoes').insert({
        'cliente_id': clienteId,
        'diarista_id': diaristId,
        'nota': nota,
        'comentario': comentario,
        'criado_em': DateTime.now().toIso8601String(),
      });

      // Atualizar média de avaliação da diarista
      await _atualizarAvaliacaoMedia(diaristId);
    } catch (e) {
      throw Exception('Erro ao criar avaliação: $e');
    }
  }

  /// Obter avaliações de uma diarista
  Future<List<Avaliacao>> getAvaliacoesDiarista(String diaristId) async {
    try {
      final response = await _supabase
          .from('avaliacoes')
          .select()
          .eq('diarista_id', diaristId)
          .order('criado_em', ascending: false);

      return (response as List)
          .map((e) => Avaliacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar avaliações: $e');
    }
  }

  /// Atualizar média de avaliação da diarista
  Future<void> _atualizarAvaliacaoMedia(String diaristId) async {
    try {
      final avaliacoes = await getAvaliacoesDiarista(diaristId);
      
      if (avaliacoes.isEmpty) {
        return;
      }

      final media = avaliacoes.fold<double>(
        0,
        (sum, avaliacao) => sum + avaliacao.nota,
      ) / avaliacoes.length;

      await _supabase
          .from('diaristas')
          .update({'avaliacao_media': media})
          .eq('user_id', diaristId);
    } catch (e) {
      throw Exception('Erro ao atualizar media de avaliacao: $e');
    }
  }

  // ============== ADMIN OPERATIONS ==============

  /// Buscar todos os usuarios (apenas admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, nome, email, tipo_usuario, criado_em')
          .order('criado_em', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erro ao buscar usuarios: $e');
    }
  }

  /// Buscar todas as solicitacoes (apenas admin)
  Future<List<Map<String, dynamic>>> getAllSolicitacoes() async {
    try {
      final response = await _supabase
          .from('solicitacoes')
          .select('id, descricao, endereco, status, data_agendada, criado_em')
          .order('criado_em', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Erro ao buscar solicitacoes: $e');
    }
  }

  /// Estatisticas gerais para o painel admin
  Future<Map<String, int>> getAdminStats() async {
    try {
      final users = await _supabase.from('users').select('tipo_usuario');
      final solicitacoes = await _supabase.from('solicitacoes').select('id');

      final userList = users as List;
      final total = userList.length;
      final clientes =
          userList.where((u) => u['tipo_usuario'] == 'cliente').length;
      final diaristas =
          userList.where((u) => u['tipo_usuario'] == 'diarista').length;

      return {
        'total_usuarios': total,
        'total_clientes': clientes,
        'total_diaristas': diaristas,
        'total_solicitacoes': (solicitacoes as List).length,
      };
    } catch (_) {
      return {
        'total_usuarios': 0,
        'total_clientes': 0,
        'total_diaristas': 0,
        'total_solicitacoes': 0,
      };
    }
  }
}
