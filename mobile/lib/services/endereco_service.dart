import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/endereco_cliente.dart';

/// Serviço de CRUD para endereços do cliente
class EnderecoService {
  final _supabase = Supabase.instance.client;

  /// Busca todos os endereços do cliente ordenados: principal primeiro
  Future<List<EnderecoCliente>> getEnderecos(String clienteId) async {
    try {
      final response = await _supabase
          .from('enderecos_cliente')
          .select()
          .eq('cliente_id', clienteId)
          .order('principal', ascending: false)
          .order('criado_em');

      return (response as List)
          .map((e) => EnderecoCliente.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar endereços: $e');
    }
  }

  /// Cria um novo endereço. Se `principal == true`, desmarca os outros.
  Future<EnderecoCliente> criarEndereco(EnderecoCliente endereco) async {
    try {
      if (endereco.principal) {
        await _desmarcarPrincipal(endereco.clienteId);
      }

      final response = await _supabase
          .from('enderecos_cliente')
          .insert(endereco.toJson())
          .select()
          .single();

      return EnderecoCliente.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao criar endereço: $e');
    }
  }

  /// Atualiza um endereço existente
  Future<EnderecoCliente> atualizarEndereco(EnderecoCliente endereco) async {
    try {
      if (endereco.principal) {
        await _desmarcarPrincipal(endereco.clienteId);
      }

      final response = await _supabase
          .from('enderecos_cliente')
          .update(endereco.toJson())
          .eq('id', endereco.id)
          .select()
          .single();

      return EnderecoCliente.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erro ao atualizar endereço: $e');
    }
  }

  /// Remove um endereço
  Future<void> removerEndereco(String id) async {
    try {
      await _supabase.from('enderecos_cliente').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao remover endereço: $e');
    }
  }

  /// Define um endereço como principal
  Future<void> definirPrincipal({
    required String enderecoId,
    required String clienteId,
  }) async {
    try {
      await _desmarcarPrincipal(clienteId);
      await _supabase
          .from('enderecos_cliente')
          .update({'principal': true}).eq('id', enderecoId);
    } catch (e) {
      throw Exception('Erro ao definir endereço principal: $e');
    }
  }

  Future<void> _desmarcarPrincipal(String clienteId) async {
    await _supabase
        .from('enderecos_cliente')
        .update({'principal': false})
        .eq('cliente_id', clienteId)
        .eq('principal', true);
  }
}
