import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de autenticação com Supabase
class AuthService {
  final _supabase = Supabase.instance.client;

  /// Obter sessão atual
  Session? get currentSession => _supabase.auth.currentSession;

  /// Verificar se usuário está autenticado
  bool get isAuthenticated => currentSession != null;

  /// Obter ID do usuário atual
  String? get currentUserId => currentSession?.user.id;

  /// Registrar novo usuário
  /// 
  /// [email] Email do usuário
  /// [password] Senha (mínimo 6 caracteres)
  /// [nome] Nome completo
  /// [tipoUsuario] 'cliente' ou 'diarista'
  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String nome,
    required String tipoUsuario,
  }) async {
    try {
      // Criar autenticação no Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Inserir dados do usuário na tabela 'users'
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'nome': nome,
          'tipo_usuario': tipoUsuario,
          'criado_em': DateTime.now().toIso8601String(),
        });

        // Se é diarista, criar perfil inicial
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
          // Inserir cliente
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

  /// Fazer login
  /// 
  /// [email] Email do usuário
  /// [password] Senha
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Erro no login: ${e.message}');
    }
  }

  /// Fazer logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Erro ao fazer logout: ${e.message}');
    }
  }

  /// Redefinir senha
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Erro ao redefinir senha: ${e.message}');
    }
  }

  /// Obter usuário atual
  User? get user => _supabase.auth.currentUser;

  /// Stream de autenticação - ouça mudanças de sessão
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
