-- ========================================================================
-- aDiarista - Migração: Suporte a Admin
-- ========================================================================
-- Execute este script no SQL Editor do Supabase:
-- https://app.supabase.com/project/_/sql/new
-- ========================================================================

-- ========================================================================
-- 1. ADICIONAR 'admin' COMO TIPO DE USUÁRIO VÁLIDO
-- ========================================================================

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_tipo_usuario_check;

ALTER TABLE users
  ADD CONSTRAINT users_tipo_usuario_check
  CHECK (tipo_usuario IN ('cliente', 'diarista', 'admin'));

-- ========================================================================
-- 2. FUNÇÃO AUXILIAR SECURITY DEFINER (evita recursão infinita no RLS)
-- ========================================================================
-- SECURITY DEFINER faz a função rodar com privilégios do owner (bypassa RLS),
-- impedindo que a política consulte 'users' de dentro de uma avaliação de 'users'.

CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND tipo_usuario = 'admin'
  );
$$;

-- ========================================================================
-- 3. POLÍTICA DE INSERT para signup (usuários inserem seu próprio registro)
-- ========================================================================

-- Necessário para o cadastro funcionar (auth.uid() = id no novo registro)
CREATE POLICY users_insert_own ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ========================================================================
-- 4. POLÍTICAS RLS PARA ADMIN (usam is_admin() para evitar recursão)
-- ========================================================================

-- Remover políticas antigas se existirem (para re-executar com segurança)
DROP POLICY IF EXISTS admin_users_all ON users;
DROP POLICY IF EXISTS admin_clientes_all ON clientes;
DROP POLICY IF EXISTS admin_diaristas_all ON diaristas;
DROP POLICY IF EXISTS admin_solicitacoes_all ON solicitacoes;
DROP POLICY IF EXISTS admin_avaliacoes_all ON avaliacoes;

CREATE POLICY admin_users_all ON users
  FOR ALL
  USING (is_admin());

CREATE POLICY admin_clientes_all ON clientes
  FOR ALL
  USING (is_admin());

CREATE POLICY admin_diaristas_all ON diaristas
  FOR ALL
  USING (is_admin());

CREATE POLICY admin_solicitacoes_all ON solicitacoes
  FOR ALL
  USING (is_admin());

CREATE POLICY admin_avaliacoes_all ON avaliacoes
  FOR ALL
  USING (is_admin());

-- ========================================================================
-- MIGRAÇÃO CONCLUÍDA!
-- ========================================================================
-- ✅ Constraint atualizada para incluir 'admin'
-- ✅ Função is_admin() com SECURITY DEFINER (sem recursão infinita)
-- ✅ Política INSERT para signup funcionar
-- ✅ Políticas RLS de admin criadas
--
-- PRÓXIMO PASSO:
-- 1. Acesse o app e crie sua conta normalmente (como 'cliente')
-- 2. Volte aqui e execute o UPDATE abaixo substituindo seu email:
--
--    UPDATE users SET tipo_usuario = 'admin' WHERE email = 'seu@email.com';
--
-- ========================================================================

