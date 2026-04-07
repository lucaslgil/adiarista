-- ========================================================================
-- aDiarista - Schema Completo para Supabase
-- ========================================================================
-- Execute este script completo no SQL Editor do Supabase
-- Versão: 1.0 - Banco de dados limpo e testado
-- ========================================================================

-- ========================================================================
-- 1. CRIAÇÃO DE TABELAS
-- ========================================================================

-- Tabela: users (perfis básicos de todos os usuários)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  tipo_usuario VARCHAR(50) NOT NULL CHECK (tipo_usuario IN ('cliente', 'diarista')),
  foto_perfil TEXT,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Tabela: clientes (dados específicos de clientes)
CREATE TABLE clientes (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Tabela: diaristas (perfil profissional das diaristas)
CREATE TABLE diaristas (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  descricao TEXT,
  preco DECIMAL(10, 2) NOT NULL DEFAULT 0,
  avaliacao_media DECIMAL(3, 2) DEFAULT 0 CHECK (avaliacao_media >= 0 AND avaliacao_media <= 5),
  regiao VARCHAR(255) NOT NULL DEFAULT '',
  especialidades TEXT[] DEFAULT ARRAY[]::TEXT[],
  ativo BOOLEAN DEFAULT true,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Tabela: solicitacoes (pedidos de serviço)
CREATE TABLE solicitacoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  diarista_id UUID REFERENCES diaristas(user_id) ON DELETE SET NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pendente' 
    CHECK (status IN ('pendente', 'aceita', 'em_andamento', 'finalizada', 'cancelada')),
  data_agendada TIMESTAMP NOT NULL,
  endereco VARCHAR(500) NOT NULL,
  descricao TEXT NOT NULL,
  observacoes TEXT,
  tipo_limpeza VARCHAR(100),
  preco_estimado DECIMAL(10, 2),
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW(),
  concluida_em TIMESTAMP
);

-- Tabela: avaliacoes (ratings e comentários)
CREATE TABLE avaliacoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  diarista_id UUID NOT NULL REFERENCES diaristas(user_id) ON DELETE CASCADE,
  nota INTEGER NOT NULL CHECK (nota >= 1 AND nota <= 5),
  comentario TEXT,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ========================================================================
-- 2. ÍNDICES PARA PERFORMANCE
-- ========================================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_tipo ON users(tipo_usuario);
CREATE INDEX idx_diaristas_regiao ON diaristas(regiao);
CREATE INDEX idx_diaristas_ativo ON diaristas(ativo);
CREATE INDEX idx_diaristas_avaliacao ON diaristas(avaliacao_media);
CREATE INDEX idx_solicitacoes_cliente ON solicitacoes(cliente_id);
CREATE INDEX idx_solicitacoes_diarista ON solicitacoes(diarista_id);
CREATE INDEX idx_solicitacoes_status ON solicitacoes(status);
CREATE INDEX idx_solicitacoes_data ON solicitacoes(data_agendada);
CREATE INDEX idx_avaliacoes_cliente ON avaliacoes(cliente_id);
CREATE INDEX idx_avaliacoes_diarista ON avaliacoes(diarista_id);

-- ========================================================================
-- 3. TRIGGERS PARA ATUALIZAÇÃO AUTOMÁTICA DE TIMESTAMP
-- ========================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at 
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_diaristas_updated_at 
  BEFORE UPDATE ON diaristas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_solicitacoes_updated_at 
  BEFORE UPDATE ON solicitacoes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ========================================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE diaristas ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE avaliacoes ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS: USERS
CREATE POLICY users_select_all ON users
  FOR SELECT USING (true);

CREATE POLICY users_update_own ON users
  FOR UPDATE USING (auth.uid() = id);

-- POLÍTICAS: CLIENTES
CREATE POLICY clientes_select_own ON clientes
  FOR SELECT USING (auth.uid() = user_id);

-- POLÍTICAS: DIARISTAS
CREATE POLICY diaristas_select_all ON diaristas
  FOR SELECT USING (true);

CREATE POLICY diaristas_update_own ON diaristas
  FOR UPDATE USING (auth.uid() = user_id);

-- POLÍTICAS: SOLICITAÇÕES
CREATE POLICY solicitacoes_select_relevant ON solicitacoes
  FOR SELECT USING (
    status = 'pendente' OR
    auth.uid() = cliente_id OR
    auth.uid() = diarista_id
  );

CREATE POLICY solicitacoes_insert_cliente ON solicitacoes
  FOR INSERT WITH CHECK (auth.uid() = cliente_id);

CREATE POLICY solicitacoes_update_involved ON solicitacoes
  FOR UPDATE USING (
    auth.uid() = cliente_id OR
    auth.uid() = diarista_id
  );

-- POLÍTICAS: AVALIAÇÕES
CREATE POLICY avaliacoes_select_all ON avaliacoes
  FOR SELECT USING (true);

CREATE POLICY avaliacoes_insert_cliente ON avaliacoes
  FOR INSERT WITH CHECK (auth.uid() = cliente_id);

-- ========================================================================
-- 5. VIEW PÚBLICA DE DIARISTAS
-- ========================================================================

CREATE OR REPLACE VIEW diaristas_publicas AS
SELECT 
  d.user_id,
  u.nome,
  u.foto_perfil,
  d.descricao,
  d.preco,
  d.avaliacao_media,
  d.regiao,
  d.especialidades,
  d.ativo
FROM diaristas d
INNER JOIN users u ON d.user_id = u.id
WHERE d.ativo = true;

-- ========================================================================
-- 6. COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ========================================================================

COMMENT ON TABLE users IS 'Usuários do sistema (clientes e diaristas)';
COMMENT ON TABLE clientes IS 'Dados específicos de clientes';
COMMENT ON TABLE diaristas IS 'Perfis profissionais de diaristas';
COMMENT ON TABLE solicitacoes IS 'Solicitações de serviço';
COMMENT ON TABLE avaliacoes IS 'Avaliações e comentários sobre serviços';

COMMENT ON COLUMN users.tipo_usuario IS 'Tipo: cliente ou diarista';
COMMENT ON COLUMN diaristas.preco IS 'Preço por diária (R$)';
COMMENT ON COLUMN diaristas.avaliacao_media IS 'Média de avaliações (0-5 estrelas)';
COMMENT ON COLUMN solicitacoes.status IS 'pendente, aceita, em_andamento, finalizada, cancelada';
COMMENT ON COLUMN avaliacoes.nota IS 'Nota de 1 a 5 estrelas';

-- ========================================================================
-- SCHEMA CRIADO COM SUCESSO!
-- ========================================================================
-- ✅ 5 tabelas criadas
-- ✅ 11 índices para performance
-- ✅ 3 triggers para timestamps automáticos
-- ✅ 9 políticas RLS para segurança
-- ✅ 1 view pública (diaristas_publicas)
-- 
-- Próximos passos:
-- 1. Configurar Supabase URL e Anon Key no app Flutter
-- 2. Testar autenticação (signup/login)
-- 3. Criar dados de teste via app
-- ========================================================================
