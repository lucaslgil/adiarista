-- ============================================================================
-- MIGRAÇÃO 007: Controle de Horários e Duração de Serviços
-- ============================================================================
-- Execute no SQL Editor do Supabase (https://supabase.com/dashboard)
-- ============================================================================

-- ─── Adicionar duração na tabela de solicitações ──────────────────────────────
-- Permite calcular hora_fim = data_agendada + duracao_minutos

ALTER TABLE solicitacoes
  ADD COLUMN IF NOT EXISTS duracao_minutos INTEGER;

-- ─── Garantir tabela de configurações de agenda ───────────────────────────────
-- (Deve ter sido criada na migração 005, mas garantimos aqui)

CREATE TABLE IF NOT EXISTS configuracoes_agenda (
  id                          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  diarista_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hora_inicio_padrao          VARCHAR(5) NOT NULL DEFAULT '08:00',
  hora_fim_padrao             VARCHAR(5) NOT NULL DEFAULT '17:00',
  tempo_deslocamento_minutos  INTEGER NOT NULL DEFAULT 30,
  criado_em                   TIMESTAMPTZ DEFAULT NOW(),
  atualizado_em               TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (diarista_id)
);

-- Trigger de timestamp
DROP TRIGGER IF EXISTS trg_configuracoes_agenda_updated ON configuracoes_agenda;
CREATE TRIGGER trg_configuracoes_agenda_updated
  BEFORE UPDATE ON configuracoes_agenda
  FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp_generica();

-- RLS
ALTER TABLE configuracoes_agenda ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "diarista_gerencia_configuracao_agenda" ON configuracoes_agenda;
CREATE POLICY "diarista_gerencia_configuracao_agenda"
  ON configuracoes_agenda FOR ALL
  USING (diarista_id = auth.uid())
  WITH CHECK (diarista_id = auth.uid());

DROP POLICY IF EXISTS "publico_visualiza_configuracao_agenda" ON configuracoes_agenda;
CREATE POLICY "publico_visualiza_configuracao_agenda"
  ON configuracoes_agenda FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM diaristas
      WHERE diaristas.user_id = configuracoes_agenda.diarista_id
        AND diaristas.ativo = true
    )
  );

-- Índice
CREATE INDEX IF NOT EXISTS idx_configuracoes_agenda_diarista
  ON configuracoes_agenda (diarista_id);

-- ─── Verificação ──────────────────────────────────────────────────────────────
-- SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'solicitacoes' AND column_name = 'duracao_minutos';
