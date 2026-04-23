-- =====================================================================
-- 010_filtro_duplo_diarista.sql
-- Suporte a Filtro Duplo: Territorial (Cidade) + Raio de Ação
-- =====================================================================

-- ── Coluna de geolocalização na tabela de diaristas (base residencial) ──
ALTER TABLE diaristas
  ADD COLUMN IF NOT EXISTS latitude           NUMERIC(10, 8),
  ADD COLUMN IF NOT EXISTS longitude          NUMERIC(11, 8),

  -- Lista de cidades atendidas (comparada ao ID/nome da cidade do serviço)
  ADD COLUMN IF NOT EXISTS cidades_atendidas  TEXT[]  NOT NULL DEFAULT '{}',

  -- Filtro por raio de ação (opcional)
  ADD COLUMN IF NOT EXISTS limitar_por_raio   BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS raio_km            NUMERIC(5, 1) NOT NULL DEFAULT 20.0;

-- Índice GIN para consultas de containment em cidades_atendidas
CREATE INDEX IF NOT EXISTS idx_diaristas_cidades_atendidas
  ON diaristas USING GIN(cidades_atendidas);

-- ── Geolocalização nos endereços do cliente ──
-- Preenchida via geocoding no front-end (ex: ViaCEP + geocoder)
ALTER TABLE enderecos_cliente
  ADD COLUMN IF NOT EXISTS latitude  NUMERIC(10, 8),
  ADD COLUMN IF NOT EXISTS longitude NUMERIC(11, 8);

-- ── Comentários de domínio ──
COMMENT ON COLUMN diaristas.latitude           IS 'Latitude da base residencial da diarista (origem do cálculo de raio)';
COMMENT ON COLUMN diaristas.longitude          IS 'Longitude da base residencial da diarista';
COMMENT ON COLUMN diaristas.cidades_atendidas  IS 'Array de nomes de cidade (normalizado em minúsculas, sem acentos) que a diarista atende. Filtro mandatório.';
COMMENT ON COLUMN diaristas.limitar_por_raio   IS 'Se true, aplica filtro adicional de distância usando raio_km';
COMMENT ON COLUMN diaristas.raio_km            IS 'Raio máximo de atendimento em km a partir da base residencial (padrão: 20 km)';
COMMENT ON COLUMN enderecos_cliente.latitude   IS 'Latitude do endereço de serviço (usado no cálculo Haversine)';
COMMENT ON COLUMN enderecos_cliente.longitude  IS 'Longitude do endereço de serviço';
