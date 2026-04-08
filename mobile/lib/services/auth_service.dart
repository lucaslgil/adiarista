import 'package:supabase_flutter/supabase_flutter.dart';

/// Servico de autenticacao com Supabase
class AuthService {
  final _supabase = Supabase.instance.client;

  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentSession != null;
  String? get currentUserId => currentSession?.user.id;

  /// Buscar tipo do usuario logado diretamente do banco
  Future<String?> getCurrentUserType() async {
    final userId = currentUserId;
    if (userId == null) return null;
    try {
      final response = await _supabase
          .from('users')
          .select('tipo_usuario')
          .eq('id', userId)
          .single();
      return response['tipo_usuario'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Cadastrar novo usuario
  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String nome,
    required String tipoUsuario,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'nome': nome,
          'tipo_usuario': tipoUsuario,
          'criado_em': DateTime.now().toIso8601String(),
        });

        if (tipoUsuario == 'diarista') {
          await _supabase.from('diaristas').insert({
            'user_id': response.user!.id,
            'descricao': '',
            'preco': 0.0,
            'avaliacao_media': 0.0,
            'regiao': '',
            'especialidades': [],
            'ativo': true,
            'criado_em': DateTime.now().toIso8601String(),
          });
        } else if (tipoUsuario == 'cliente') {
          await _supabase.from('clientes').insert({
            'user_id': response.user!.id,
            'criado_em': DateTime.now().toIso8601String(),
          });
        }
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Erro no cadastro: ${e.message}');
    }
  }

  /// Fazer login - retorna o tipo do usuario apos autenticar
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final tipo = await getCurrentUserType();
      return tipo ?? 'cliente';
    } on AuthException catch (e) {
      throw Exception('Erro no login: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Erro ao fazer logout: ${e.message}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Erro ao redefinir senha: ${e.message}');
    }
  }

  User? get user => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}