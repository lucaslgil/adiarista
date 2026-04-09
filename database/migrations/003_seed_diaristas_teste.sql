-- ========================================================================
-- aDiarista - Seed: 5 Diaristas de Teste
-- ========================================================================
-- Execute este script no SQL Editor do Supabase:
-- https://app.supabase.com/project/tjenoowimxcsenuzpcyf/sql/new
--
-- ⚠️  Este script cria usuários diretamente em auth.users.
--     Use apenas em ambiente de desenvolvimento/teste.
--
-- Credenciais de acesso de todas as diaristas:
--   Senha: Teste123!
-- ========================================================================

DO $$
DECLARE
  uid1 UUID := gen_random_uuid();
  uid2 UUID := gen_random_uuid();
  uid3 UUID := gen_random_uuid();
  uid4 UUID := gen_random_uuid();
  uid5 UUID := gen_random_uuid();
BEGIN

  -- ──────────────────────────────────────────────────────────────────────
  -- 1. Criar contas na tabela auth.users (autenticação)
  -- ──────────────────────────────────────────────────────────────────────
  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
  ) VALUES
    (
      uid1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'maria.silva.teste@adiarista.com',
      crypt('Teste123!', gen_salt('bf')),
      NOW(), NOW(), NOW(),
      '{"nome": "Maria Silva", "tipo_usuario": "diarista"}'::jsonb,
      '', '', '', ''
    ),
    (
      uid2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'ana.oliveira.teste@adiarista.com',
      crypt('Teste123!', gen_salt('bf')),
      NOW(), NOW(), NOW(),
      '{"nome": "Ana Oliveira", "tipo_usuario": "diarista"}'::jsonb,
      '', '', '', ''
    ),
    (
      uid3, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'fernanda.santos.teste@adiarista.com',
      crypt('Teste123!', gen_salt('bf')),
      NOW(), NOW(), NOW(),
      '{"nome": "Fernanda Santos", "tipo_usuario": "diarista"}'::jsonb,
      '', '', '', ''
    ),
    (
      uid4, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'juliana.costa.teste@adiarista.com',
      crypt('Teste123!', gen_salt('bf')),
      NOW(), NOW(), NOW(),
      '{"nome": "Juliana Costa", "tipo_usuario": "diarista"}'::jsonb,
      '', '', '', ''
    ),
    (
      uid5, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'patricia.souza.teste@adiarista.com',
      crypt('Teste123!', gen_salt('bf')),
      NOW(), NOW(), NOW(),
      '{"nome": "Patrícia Souza", "tipo_usuario": "diarista"}'::jsonb,
      '', '', '', ''
    );

  -- ──────────────────────────────────────────────────────────────────────
  -- 2. Criar perfis na tabela public.users
  -- ──────────────────────────────────────────────────────────────────────
  INSERT INTO public.users (id, nome, email, tipo_usuario, criado_em, atualizado_em)
  VALUES
    (uid1, 'Maria Silva',    'maria.silva.teste@adiarista.com',    'diarista', NOW(), NOW()),
    (uid2, 'Ana Oliveira',   'ana.oliveira.teste@adiarista.com',   'diarista', NOW(), NOW()),
    (uid3, 'Fernanda Santos','fernanda.santos.teste@adiarista.com','diarista', NOW(), NOW()),
    (uid4, 'Juliana Costa',  'juliana.costa.teste@adiarista.com',  'diarista', NOW(), NOW()),
    (uid5, 'Patrícia Souza', 'patricia.souza.teste@adiarista.com', 'diarista', NOW(), NOW());

  -- ──────────────────────────────────────────────────────────────────────
  -- 3. Criar perfis profissionais na tabela public.diaristas
  -- ──────────────────────────────────────────────────────────────────────
  INSERT INTO public.diaristas (
    user_id, descricao, preco, avaliacao_media, regiao, especialidades, ativo, criado_em, atualizado_em
  ) VALUES
    (
      uid1,
      'Profissional dedicada com mais de 6 anos de experiência em limpeza residencial. Pontual, organizada e de confiança.',
      120.00, 4.8,
      'São Paulo - SP',
      ARRAY['Limpeza geral', 'Cozinha', 'Banheiro', 'Varredura e lavagem'],
      true, NOW(), NOW()
    ),
    (
      uid2,
      'Especialista em limpeza pesada e organização de ambientes. Atendo condomínios e residências de qualquer porte.',
      140.00, 4.6,
      'São Paulo - SP',
      ARRAY['Limpeza pesada', 'Organização', 'Pós-obra', 'Vidros e janelas'],
      true, NOW(), NOW()
    ),
    (
      uid3,
      'Ótima comunicação e cuidado com detalhes. Experiência com limpeza geral e passagem de roupas.',
      100.00, 4.9,
      'Guarulhos - SP',
      ARRAY['Limpeza geral', 'Passagem de roupas', 'Dobra e organização de roupas'],
      true, NOW(), NOW()
    ),
    (
      uid4,
      'Certificada em limpeza pós-obra e experiência com imóveis para entrega. Trabalho rápido e de qualidade.',
      160.00, 4.5,
      'São Paulo - SP',
      ARRAY['Pós-obra', 'Limpeza de azulejos', 'Remoção de entulho leve', 'Vidros'],
      true, NOW(), NOW()
    ),
    (
      uid5,
      'Atendimento premium com produtos de qualidade. Especializada em casas de alto padrão e apartamentos.',
      150.00, 5.0,
      'São Paulo - SP',
      ARRAY['Limpeza premium', 'Conservação de pisos nobres', 'Objetos de decoração', 'Cozinha gourmet'],
      true, NOW(), NOW()
    );

  RAISE NOTICE '✅ 5 diaristas de teste criadas com sucesso!';
  RAISE NOTICE '   maria.silva.teste@adiarista.com    | Senha: Teste123!';
  RAISE NOTICE '   ana.oliveira.teste@adiarista.com   | Senha: Teste123!';
  RAISE NOTICE '   fernanda.santos.teste@adiarista.com| Senha: Teste123!';
  RAISE NOTICE '   juliana.costa.teste@adiarista.com  | Senha: Teste123!';
  RAISE NOTICE '   patricia.souza.teste@adiarista.com | Senha: Teste123!';

END $$;
