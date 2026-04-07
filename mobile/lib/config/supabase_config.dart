/// Configurações do Supabase
/// 
/// ⚠️ ATENÇÃO - BOAS PRÁTICAS DE SEGURANÇA:
/// 
/// ✅ ANON KEY: Pode ser exposta no código frontend (é pública e protegida por RLS)
/// ❌ SERVICE KEY: NUNCA commite ou exponha no frontend!
/// 
/// Para produção, considere usar flutter_dotenv ou variáveis de ambiente.
/// Obtenha credenciais em: https://app.supabase.com/project/_/settings/api
class SupabaseConfig {
  /// URL do projeto Supabase
  static const String supabaseUrl = 'https://tjenoowimxcsenuzpcyf.supabase.co';

  /// Chave anônima (pública) do Supabase
  /// Esta chave pode ser exposta no frontend - está protegida por Row Level Security (RLS)
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqZW5vb3dpbXhjc2VudXpwY3lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTgzNTksImV4cCI6MjA5MDAzNDM1OX0.QtxJVBAM-g8AngbE7avR7Zv_mXMaE-C_H6r_5drMuSM';

  /// ⚠️ NUNCA USE A SERVICE KEY NO FRONTEND!
  /// Use apenas em backend/cloud functions
  // static const String serviceKey = 'sua-service-key-aqui';
}
