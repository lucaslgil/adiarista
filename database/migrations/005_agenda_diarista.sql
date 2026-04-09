-- ========================================================================
-- aDiarista - Migração: Sistema de Agenda para Diaristas
-- ========================================================================
-- Permite que diaristas gerenciem 2 horários por dia:
-- - Meio Período (4h)
-- - Período Integral (8h)
-- ========================================================================

-- ========================================================================
-- 1. TABELA: Configuração Base da Agenda (Horário Comercial)
-- ========================================================================
CREATE TABLE IF NOT EXISTS configuracao_agenda (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    diarista_id UUID NOT NULL UNIQUE REFERENCES diaristas(user_id) ON DELETE CASCADE,
    hora_inicio_padrao TIME NOT NULL DEFAULT '08:00',     -- ex: 08:00
    hora_fim_padrao TIME NOT NULL DEFAULT '18:00',        -- ex: 18:00
    tempo_deslocamento_minutos INT NOT NULL DEFAULT 30,   -- tempo entre casas
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- 2. TABELA: Disponibilidade Diária (Liberar ou Bloquear)
-- ========================================================================
CREATE TABLE IF NOT EXISTS diarista_disponibilidade (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    diarista_id UUID NOT NULL REFERENCES diaristas(user_id) ON DELETE CASCADE,
    data DATE NOT NULL,
    status VARCHAR NOT NULL DEFAULT 'bloqueado',
    -- status: 'bloqueado' = dia indisponível
    --         'meio_periodo' = disponível só para 1 cliente (4h)
    --         'integral' = disponível para 1 cliente (8h) ou 2 clientes (4h+4h)
    hora_inicio TIME,       -- pode override o padrão
    hora_fim TIME,
    notas TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diarista_id, data)
);

-- ========================================================================
-- 3. TABELA: Agendamentos (Contratos de Clientes)
-- ========================================================================
-- Nota: Esta tabela provavelmente já existe (solicitacoes)
-- Aqui vamos criar uma estrutura mais específica para tracking

CREATE TABLE IF NOT EXISTS agendamentos_diarista (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    diarista_id UUID NOT NULL REFERENCES diaristas(user_id) ON DELETE CASCADE,
    cliente_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    data_agendamento DATE NOT NULL,
    horario_inicio TIME NOT NULL,
    horario_fim TIME NOT NULL,
    tipo_servico VARCHAR NOT NULL,
    -- tipo_servico: 'meio_periodo' (4h) ou 'integral' (8h)
    status VARCHAR NOT NULL DEFAULT 'pendente',
    -- status: 'pendente', 'confirmado', 'em_progresso', 'finalizado', 'cancelado'
    endereco TEXT,
    observacoes TEXT,
    valor_acordado DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diarista_id, data_agendamento, horario_inicio)
);

-- ========================================================================
-- 4. ÍNDICES para Performance
-- ========================================================================
CREATE INDEX idx_diarista_data ON diarista_disponibilidade(diarista_id, data);
CREATE INDEX idx_agendamentos_diarista_data ON agendamentos_diarista(diarista_id, data_agendamento);
CREATE INDEX idx_agendamentos_status ON agendamentos_diarista(status);

-- ========================================================================
-- 5. FUNÇÃO: Verificar Disponibilidade
-- ========================================================================
CREATE OR REPLACE FUNCTION verificar_disponibilidade_diarista(
    p_diarista_id UUID,
    p_data DATE,
    p_tipo_servico VARCHAR  -- 'meio_periodo' ou 'integral'
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar se algum agendamento confirmado já existe para essa data
    IF p_tipo_servico = 'integral' THEN
        -- Não pode ter NENHUM agendamento confirmado no dia se for integral
        RETURN NOT EXISTS (
            SELECT 1 FROM agendamentos_diarista
            WHERE diarista_id = p_diarista_id
            AND data_agendamento = p_data
            AND status IN ('confirmado', 'em_progresso')
        );
    ELSIF p_tipo_servico = 'meio_periodo' THEN
        -- Pode ter apenas 1 agendamento de meio período já confirmado
        RETURN (
            SELECT COUNT(*) FROM agendamentos_diarista
            WHERE diarista_id = p_diarista_id
            AND data_agendamento = p_data
            AND status IN ('confirmado', 'em_progresso')
        ) < 2;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================================================
-- 6. RLS POLICIES - Segurança
-- ========================================================================
ALTER TABLE configuracao_agenda ENABLE ROW LEVEL SECURITY;
ALTER TABLE diarista_disponibilidade ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos_diarista ENABLE ROW LEVEL SECURITY;

-- Diarista pode ver/editar apenas sua própria configuração
CREATE POLICY diarista_config_self ON configuracao_agenda
    FOR ALL
    USING (diarista_id = auth.uid());

-- Diarista pode ver/editar apenas sua disponibilidade
CREATE POLICY diarista_disponibilidade_self ON diarista_disponibilidade
    FOR ALL
    USING (diarista_id = auth.uid());

-- Clientes podem VER a disponibilidade de qualquer diarista (read-only)
CREATE POLICY cliente_ver_disponibilidade ON diarista_disponibilidade
    FOR SELECT
    USING (true);

-- Diarista pode ver/editar apenas seus agendamentos
CREATE POLICY diarista_agendamentos_self ON agendamentos_diarista
    FOR ALL
    USING (diarista_id = auth.uid());

-- Cliente pode ver seus próprios agendamentos e criar novos
CREATE POLICY cliente_agendamentos_self ON agendamentos_diarista
    FOR SELECT
    USING (cliente_id = auth.uid());

CREATE POLICY cliente_agendamentos_insert ON agendamentos_diarista
    FOR INSERT
    WITH CHECK (cliente_id = auth.uid());

-- ========================================================================
-- MIGRAÇÃO CONCLUÍDA!
-- ========================================================================
-- ✅ Tabela configuracao_agenda criada
-- ✅ Tabela diarista_disponibilidade criada
-- ✅ Tabela agendamentos_diarista criada
-- ✅ Função de validação criada
-- ✅ Índices criados para performance
-- ✅ RLS policies implementadas
--
-- PRÓXIMO PASSO:
-- Implementar models Dart e lógica de validação no Flutter
-- ========================================================================
