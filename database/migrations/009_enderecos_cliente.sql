-- =====================================================================
-- 009_enderecos_cliente.sql
-- Tabela de endereços cadastrados por clientes
-- =====================================================================

CREATE TABLE IF NOT EXISTS enderecos_cliente (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  apelido     TEXT NOT NULL,                    -- Ex: "Casa", "Trabalho"
  logradouro  TEXT NOT NULL,
  numero      TEXT NOT NULL,
  complemento TEXT,
  bairro      TEXT NOT NULL,
  cidade      TEXT NOT NULL,
  estado      CHAR(2) NOT NULL,
  cep         TEXT NOT NULL,
  principal   BOOLEAN NOT NULL DEFAULT FALSE,
  criado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para busca por cliente
CREATE INDEX IF NOT EXISTS idx_enderecos_cliente_cliente_id
  ON enderecos_cliente(cliente_id);

-- Garante que cada cliente tenha no máximo 1 endereço principal
CREATE UNIQUE INDEX IF NOT EXISTS idx_enderecos_cliente_principal
  ON enderecos_cliente(cliente_id)
  WHERE principal = TRUE;

-- RLS: cliente só vê e manipula os próprios endereços
ALTER TABLE enderecos_cliente ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cliente vê seus próprios endereços"
  ON enderecos_cliente FOR SELECT
  USING (auth.uid() = cliente_id);

CREATE POLICY "Cliente cria seus próprios endereços"
  ON enderecos_cliente FOR INSERT
  WITH CHECK (auth.uid() = cliente_id);

CREATE POLICY "Cliente atualiza seus próprios endereços"
  ON enderecos_cliente FOR UPDATE
  USING (auth.uid() = cliente_id);

CREATE POLICY "Cliente remove seus próprios endereços"
  ON enderecos_cliente FOR DELETE
  USING (auth.uid() = cliente_id);
