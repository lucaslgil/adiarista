-- ============================================================================
-- MIGRAÇÃO 008: Disponibilidade Padrão (dias_trabalho)
-- ============================================================================
-- Execute no SQL Editor do Supabase (https://supabase.com/dashboard)
-- ============================================================================

-- ─── 1. Dias de trabalho na configuração de agenda ───────────────────────────
-- Convenção: 0=Dom, 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sab
-- Padrão: Segunda a Sexta (1,2,3,4,5)

ALTER TABLE configuracoes_agenda
  ADD COLUMN IF NOT EXISTS dias_trabalho INTEGER[] NOT NULL DEFAULT '{1,2,3,4,5}';

-- ─── 2. Tabela de bloqueios recorrentes (criada aqui caso não exista) ────────

CREATE TABLE IF NOT EXISTS diarista_bloqueio_recorrente (
  id           UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  diarista_id  UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo         VARCHAR(10)  NOT NULL CHECK (tipo IN ('semanal', 'mensal')),
  valor        INTEGER      NOT NULL,
  data_inicio  DATE         NOT NULL DEFAULT CURRENT_DATE,
  data_fim     DATE,
  ativo        BOOLEAN      NOT NULL DEFAULT true,
  criado_em    TIMESTAMPTZ  DEFAULT NOW()
);

ALTER TABLE diarista_bloqueio_recorrente
  ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT true;

-- RLS
ALTER TABLE diarista_bloqueio_recorrente ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "diarista_gerencia_bloqueio_recorrente" ON diarista_bloqueio_recorrente;
CREATE POLICY "diarista_gerencia_bloqueio_recorrente"
  ON diarista_bloqueio_recorrente FOR ALL
  USING (diarista_id = auth.uid())
  WITH CHECK (diarista_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_bloqueio_recorrente_ativo
  ON diarista_bloqueio_recorrente (diarista_id, ativo);

-- ─── Verificação ──────────────────────────────────────────────────────────────
-- SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'configuracoes_agenda' AND column_name = 'dias_trabalho';
