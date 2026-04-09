-- ========================================================================
-- aDiarista - Migração: Parâmetros de Serviço no MVP
-- ========================================================================
-- Execute este script no SQL Editor do Supabase:
-- https://app.supabase.com/project/tjenoowimxcsenuzpcyf/sql/new
-- ========================================================================

-- ========================================================================
-- 1. ADICIONAR COLUNA parametros EM solicitacoes
-- ========================================================================
-- JSONB para armazenar parâmetros específicos de cada tipo de serviço.
-- Compatível com registros antigos (aceita NULL).

ALTER TABLE solicitacoes
  ADD COLUMN IF NOT EXISTS parametros JSONB DEFAULT NULL;

-- ========================================================================
-- 2. ATUALIZAR CONSTRAINT DE tipo_limpeza (MVP)
-- ========================================================================
-- Remove constraint antiga se existir, e adiciona a nova limitando
-- aos 4 serviços do MVP. Registros antigos com valores diferentes
-- ficam sem constraint mas são preservados (coluna nullable).
--
-- Descomente o bloco abaixo APENAS se quiser enforçar os 4 tipos no DB:
--
-- ALTER TABLE solicitacoes
--   DROP CONSTRAINT IF EXISTS solicitacoes_tipo_limpeza_check;
--
-- ALTER TABLE solicitacoes
--   ADD CONSTRAINT solicitacoes_tipo_limpeza_check
--   CHECK (
--     tipo_limpeza IS NULL OR
--     tipo_limpeza IN (
--       'limpeza_residencial',
--       'limpeza_comercial',
--       'lavar_roupas',
--       'passar_roupas'
--     )
--   );

-- ========================================================================
-- 3. ÍNDICE PARA CONSULTAS POR PARÂMETRO (GIN para JSONB)
-- ========================================================================

CREATE INDEX IF NOT EXISTS idx_solicitacoes_parametros
  ON solicitacoes USING GIN (parametros);

-- ========================================================================
-- MIGRAÇÃO CONCLUÍDA!
-- ========================================================================
-- ✅ Coluna parametros JSONB adicionada (NULL compatível com dados antigos)
-- ✅ Índice GIN criado para buscas por parâmetro
--
-- Estrutura dos parâmetros por tipo de serviço:
--
-- limpeza_residencial:
--   { "quantidadeComodos": 3, "nivelSujeira": "medio", "possuiPets": true }
--
-- limpeza_comercial:
--   { "metragem": 120.5 }
--
-- lavar_roupas:
--   { "tamanho": "grande" }
--
-- passar_roupas:
--   { "quantidadePecas": 15 }
-- ========================================================================
