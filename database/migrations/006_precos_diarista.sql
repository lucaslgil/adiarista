-- ============================================================================
-- MIGRAÇÃO 006: Precificação de Serviços das Diaristas
-- ============================================================================
-- Execute no SQL Editor do Supabase (https://supabase.com/dashboard)
-- ============================================================================

-- ─── Tabela: servicos_diarista ───────────────────────────────────────────────
-- Registra quais tipos de serviço cada diarista oferece

CREATE TABLE IF NOT EXISTS servicos_diarista (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo_servico  VARCHAR(30) NOT NULL CHECK (tipo_servico IN (
    'limpeza_residencial',
    'limpeza_comercial',
    'lavar_roupas',
    'passar_roupas',
    'lavar_e_passar'
  )),
  ativo         BOOLEAN NOT NULL DEFAULT true,
  criado_em     TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (usuario_id, tipo_servico)
);

-- ─── Tabela: precos_diarista ─────────────────────────────────────────────────
-- Armazena a configuração de preços de cada serviço em JSONB flexível
--
-- Estrutura do campo `configuracao` por tipo_servico:
--
-- limpeza_residencial:
--   { "preco_quarto": 25, "preco_banheiro": 20, "preco_sala": 30,
--     "preco_cozinha": 30, "taxa_pet": 50 }
--
-- limpeza_comercial:
--   { "preco_por_m2": 8 }
--
-- lavar_roupas:
--   { "preco_por_hora": 30 }
--
-- passar_roupas:
--   { "modo": "por_hora", "preco_por_hora": 25, "pecas_por_hora": 20 }
--   ou
--   { "modo": "por_peca", "preco_por_peca": 5 }
--
-- lavar_e_passar:
--   { "preco_personalizado": 150 }   <-- opcional, se omitido soma lavar+passar

CREATE TABLE IF NOT EXISTS precos_diarista (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo_servico  VARCHAR(30) NOT NULL CHECK (tipo_servico IN (
    'limpeza_residencial',
    'limpeza_comercial',
    'lavar_roupas',
    'passar_roupas',
    'lavar_e_passar'
  )),
  configuracao  JSONB NOT NULL DEFAULT '{}',
  valor_minimo  NUMERIC(10, 2) NOT NULL DEFAULT 0
                CHECK (valor_minimo >= 0),
  criado_em     TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (usuario_id, tipo_servico)
);

-- ─── Trigger: atualizar atualizado_em ────────────────────────────────────────

CREATE OR REPLACE FUNCTION atualizar_timestamp_generica()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_servicos_diarista_updated ON servicos_diarista;
CREATE TRIGGER trg_servicos_diarista_updated
  BEFORE UPDATE ON servicos_diarista
  FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp_generica();

DROP TRIGGER IF EXISTS trg_precos_diarista_updated ON precos_diarista;
CREATE TRIGGER trg_precos_diarista_updated
  BEFORE UPDATE ON precos_diarista
  FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp_generica();

-- ─── Row Level Security ───────────────────────────────────────────────────────

ALTER TABLE servicos_diarista ENABLE ROW LEVEL SECURITY;
ALTER TABLE precos_diarista   ENABLE ROW LEVEL SECURITY;

-- Diarista gerencia seus próprios registros
DROP POLICY IF EXISTS "diarista_gerencia_servicos" ON servicos_diarista;
CREATE POLICY "diarista_gerencia_servicos"
  ON servicos_diarista FOR ALL
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "diarista_gerencia_precos" ON precos_diarista;
CREATE POLICY "diarista_gerencia_precos"
  ON precos_diarista FOR ALL
  USING (usuario_id = auth.uid())
  WITH CHECK (usuario_id = auth.uid());

-- Clientes e admin podem visualizar serviços/preços de diaristas ativas
DROP POLICY IF EXISTS "publico_visualiza_servicos_ativos" ON servicos_diarista;
CREATE POLICY "publico_visualiza_servicos_ativos"
  ON servicos_diarista FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM diaristas
      WHERE diaristas.user_id = servicos_diarista.usuario_id
        AND diaristas.ativo = true
    )
  );

DROP POLICY IF EXISTS "publico_visualiza_precos_ativos" ON precos_diarista;
CREATE POLICY "publico_visualiza_precos_ativos"
  ON precos_diarista FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM diaristas
      WHERE diaristas.user_id = precos_diarista.usuario_id
        AND diaristas.ativo = true
    )
  );

-- ─── Índices ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_servicos_diarista_usuario
  ON servicos_diarista (usuario_id);

CREATE INDEX IF NOT EXISTS idx_precos_diarista_usuario
  ON precos_diarista (usuario_id);

-- ─── View: diaristas_com_precos ───────────────────────────────────────────────
-- Facilita a busca de diaristas que já configuraram preços

CREATE OR REPLACE VIEW diaristas_com_precos AS
SELECT
  d.*,
  (
    SELECT COUNT(*) > 0
    FROM servicos_diarista sd
    JOIN precos_diarista pd
      ON pd.usuario_id = sd.usuario_id
     AND pd.tipo_servico = sd.tipo_servico
    WHERE sd.usuario_id = d.user_id
      AND sd.ativo = true
      AND pd.valor_minimo > 0
  ) AS precos_configurados
FROM diaristas d;

-- ─── Verificação ─────────────────────────────────────────────────────────────
-- Confirme que as tabelas foram criadas corretamente:
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public'
--   AND table_name IN ('servicos_diarista', 'precos_diarista');
