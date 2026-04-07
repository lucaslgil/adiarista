# 🎨 Arquitetura Visual - aDiarista

## Diagrama de Fluxo do Aplicativo

```
┌─────────────────────────────────────────────────────────────┐
│                    APLICATIVO aDIARISTA                      │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
            LOGIN/SIGNUP          NAVEGAÇÃO
                │                       │
        ┌───────┴───────┐               │
        ▼               ▼               │
    CLIENTE        DIARISTA            │
        │               │              │
        ├── Home        ├── Home       │
        ├── Histórico   ├── Histórico  │
        ├── Perfil      ├── Perfil     │
        └── Logout      └── Logout     └──> Supabase Backend
```

## Arquitetura em Camadas

```
┌────────────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER (UI)                    │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Screens   │  │   Widgets    │  │  Theme + Router  │  │
│  │  (LoginUI)  │  │ (CustomBtn)  │  │  (Navigation)    │  │
│  └─────────────┘  └──────────────┘  └──────────────────┘  │
└────────────────────────────────────────────────────────────┘
                            ▲
                            │ usa
                            ▼
┌────────────────────────────────────────────────────────────┐
│              BUSINESS LOGIC LAYER (Services)                │
│               ┌─────────────────────────────┐              │
│               │   AuthService               │              │
│               │   - login()                 │              │
│               │   - signup()                │              │
│               │   - logout()                │              │
│               └─────────────────────────────┘              │
│               ┌─────────────────────────────┐              │
│               │   UserService               │              │
│               │   - getUsuarios()           │              │
│               │   - criarSolicitacao()      │              │
│               │   - avaliar()               │              │
│               └─────────────────────────────┘              │
└────────────────────────────────────────────────────────────┘
                            ▲
                            │ usa
                            ▼
┌────────────────────────────────────────────────────────────┐
│              DATA LAYER (Models + Supabase)                 │
│  ┌───────────┐  ┌──────────────┐  ┌─────────────────┐    │
│  │ User      │  │ Solicitacao  │  │ DiaristaPerfil  │    │
│  │ Avaliacao │  │ etc...       │  │ etc...          │    │
│  └───────────┘  └──────────────┘  └─────────────────┘    │
│                                                            │
│              ┌──────────────────────────────┐            │
│              │    SUPABASE (Backend)        │            │
│              │  • PostgreSQL Database       │            │
│              │  • Auth (Email/Password)     │            │
│              │  • Row Level Security (RLS)  │            │
│              │  • Realtime (Websockets)     │            │
│              └──────────────────────────────┘            │
└────────────────────────────────────────────────────────────┘
```

## Fluxo de Autenticação

```
┌──────────────────┐
│   App Inicia     │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│  Existem. sessão?    │
└────────┬─────────────┘
         │
    ┌────┴─────┐
    ▼          ▼
  SIM         NÃO
   │           │
   ▼           ▼
┌─────────┐  ┌──────────┐
│ Verificar  │           │  Login Screen
│ Type User  │           │  ┌────────────┐
└─────┬─────┘           │  │ Email      │
      │                │  │ Password   │
      ├─────────┐      │  └────┬───────┘
      ▼         ▼      │       │
    ┌────┐   ┌────┐    │       ▼
    │CLI │   │DIAR│    │   ┌─────────────┐
    │ENT │   │IST │    │   │ AuthService │
    │----│   │----│    │   │ .login()    │
    │Home│   │Home│    │   └──────┬──────┘
    └────┘   └────┘    │          │
                      │          ▼
                      │     ┌────────────┐
                      │     │  Success?  │
                      │     └────┬───┬───┘
                      │          │   │
                      │        SIM NÃO
                      │          │   │
                      │          ▼   ▼
                      │       Home Error
                      │             │
                      └─────────────┘
```

## Estrutura de Dados

```
users table
├── id (UUID) [PK]
├── nome (VARCHAR)
├── email (VARCHAR) [UNIQUE]
├── tipo_usuario (VARCHAR) → 'cliente' | 'diarista'
├── foto_perfil (TEXT)
├── criado_em (TIMESTAMP)
└── atualizado_em (TIMESTAMP)

┌─────────────────
▼                │
clientes         diaristas
├── user_id [FK] ├── user_id [FK]
├── criado_em    ├── descricao
└── atualizado_em├── preco
                 ├── avaliacao_media
                 ├── regiao
                 ├── especialidades[]
                 ├── ativo
                 ├── criado_em
                 └── atualizado_em

                                 ▼
                          solicitacoes
                          ├── id (UUID) [PK]
                          ├── cliente_id [FK]
                          ├── diarista_id [FK] (nullable)
                          ├── status → 'pendente' | 'aceita' | etc
                          ├── data_agendada
                          ├── endereco
                          ├── descricao
                          ├── tipo_limpeza
                          ├── preco_estimado
                          ├── criado_em
                          ├── atualizado_em
                          └── concluida_em

                                 ▼
                              avaliacoes
                              ├── id (UUID) [PK]
                              ├── cliente_id [FK]
                              ├── diarista_id [FK]
                              ├── nota (1-5)
                              ├── comentario
                              └── criado_em
```

## Estados da Solicitação

```
┌──────────────┐
│   PENDENTE   │ ← Cliente criou, diarista não aceitou
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   ACEITA     │ ← Diarista aceitou o trabalho
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  EM ANDAMENTO    │ ← Trabalho começou
└──────┬───────────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌────────────┐    ┌─────────────┐
│ FINALIZADA │    │  CANCELADA  │
└────────────┘    └─────────────┘
       │                 │
       └────────┬────────┘
                ▼
          ┌──────────────┐
          │  AVALIAÇÃO   │
          │ (por cliente)│
          └──────────────┘
```

## Componentes e Responsabilidades

```
MODELS (lib/models/)
├─ user.dart .......................... Define usuário
├─ diarista_perfil.dart .............. Define perfil de diarista
├─ solicitacao.dart .................. Define solicitação
└─ avaliacao.dart .................... Define avaliação

SERVICES (lib/services/)
├─ auth_service.dart
│  ├─ signup()
│  ├─ login()
│  ├─ logout()
│  └─ resetPassword()
└─ user_service.dart
   ├─ DIARISTA OPS
   │  ├─ getDiaristaPerfil()
   │  ├─ updateDiaristaPerfil()
   │  └─ getDiaristasDisponiveis()
   ├─ SOLICITAÇÃO OPS
   │  ├─ criarSolicitacao()
   │  ├─ getSolicitacoesPendentes()
   │  ├─ aceitarSolicitacao()
   │  └─ atualizarStatusSolicitacao()
   └─ AVALIAÇÃO OPS
      ├─ criarAvaliacao()
      └─ getAvaliacoesDiarista()

SCREENS (lib/screens/)
├─ auth/
│  ├─ login_screen.dart ............ Tela de login
│  └─ signup_screen.dart .......... Tela de cadastro
├─ client/
│  └─ home_client_screen.dart .... Home + abas do cliente
└─ worker/
   └─ home_worker_screen.dart .... Home + abas da diarista

CONFIG (lib/config/)
├─ theme.dart ..................... Cores, tipografia
├─ router.dart .................... Navigação
└─ supabase_config.dart .......... Credenciais
```

## Fluxo de Uma Solicitação

```
1. CLIENTE CRIA SOLICITAÇÃO
   ┌──────────────────────┐
   │ Home Cliente         │
   │ → Clica no "+"      │
   └─────────┬────────────┘
             │
             ▼
   ┌─────────────────────────────┐
   │ CreateSolicitacaoScreen     │
   │ • Endereço                  │
   │ • Data/Hora                 │
   │ • Tipo de limpeza           │
   │ • Observações               │
   └─────────┬───────────────────┘
             │
             ▼
   ┌─────────────────────────────┐
   │ UserService                 │
   │ .criarSolicitacao()         │
   └─────────┬───────────────────┘
             │
             ▼
   ┌─────────────────────────────┐
   │ INSERT INTO solicitacoes    │
   │ status='pendente'           │
   └────────────────────────────┘

2. DIARISTA VISUALIZA DISPONÍVEL
   ┌──────────────────────┐
   │ Home Diarista        │
   │ →"Disponíveis"       │
   └─────────┬────────────┘
             │
             ▼
   ┌─────────────────────────────┐
   │ UserService                 │
   │ .getSolicitacoesPendentes()  │
   └─────────┬───────────────────┘
             │
             ▼
   ┌─────────────────────────────┐
   │ SELECT FROM solicitacoes    │
   │ WHERE status='pendente'     │
   └─────────┬───────────────────┘
             │
             ▼
   ┌──────────────────────┐
   │ Listar no app        │
   └──────────────────────┘

3. DIARISTA ACEITA
   ┌──────────────────────────┐
   │ Clica no "Aceitar"      │
   └─────────┬────────────────┘
             │
             ▼
   ┌────────────────────────────┐
   │ UserService                │
   │ .aceitarSolicitacao()      │
   └─────────┬──────────────────┘
             │
             ▼
   ┌────────────────────────────┐
   │ UPDATE solicitacoes        │
   │ status='aceita'            │
   │ diarista_id=<id>           │
   └────────────────────────────┘

4. CLIENTE VISUALIZA ACEITA
   ┌──────────────────────┐
   │ Home Cliente         │
   │ Atualiza automático  │
   │ ou pull-to-refresh   │
   └──────────────────────┘

5. CONCLUSÃO E AVALIAÇÃO
   ┌──────────────────────┐
   │ Marcar como completo │
   └─────────┬────────────┘
             │
             ▼
   ┌────────────────────┐
   │ UPDATE status=     │
   │ 'finalizada'       │
   └─────────┬──────────┘
             │
             ▼
   ┌──────────────────────────────┐
   │ Cliente avalia (1-5 stars)   │
   │ + comentário (opcional)      │
   └─────────┬────────────────────┘
             │
             ▼
   ┌──────────────────────────────┐
   │ INSERT INTO avaliacoes       │
   │ Calcula nova média           │
   └──────────────────────────────┘
```

## Estado da Aplicação (Provider)

```
MultiProvider
├── AuthService .................... Gerencia autenticação
│   ├─ currentSession
│   ├─ currentUserId
│   └─ isAuthenticated
│
└── UserService .................... Gerencia dados
    ├─ currentUser (stream)
    ├─ solicitacoes (stream)
    └─ diaristas (stream)
```

---

Última atualização: Janeiro 2024
