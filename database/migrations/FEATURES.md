# 📋 Documentação de Funcionalidades - aDiarista

## Funcionalidades Implementadas (MVP)

### ✅ Autenticação
- Login com email/senha
- Cadastro com seleção de tipo de usuário
- Logout
- Persistência de sessão
- Validação de dados de entrada

### ✅ Interface de Usuário
- Tema claro e escuro adaptativo
- Design responsivo
- Navegação por abas
- Loading states
- Tratamento de erros
- Toast notifications

### ✅ Cliente - Telas Implementadas
- **Home**: Visualizar solicitações ativas
- **Histórico**: Listar serviços passados (estrutura)
- **Perfil**: Dados pessoais e logout

### ✅ Diarista - Telas Implementadas
- **Disponíveis**: Listar solicitações pendentes
- **Meus Serviços**: Visualizar serviços aceitos
- **Perfil**: Dados profissionais e logout

### ✅ Integração Supabase
- Autenticação via Supabase Auth
- CRUD básico de usuários
- Estrutura de banco de dados completa
- Row Level Security (RLS) implementado
- Índices para performance

---

## Funcionalidades Planejadas (Fase 2)

### Cliente
- [ ] **Criar Solicitação**
  - Formulário completo (endereço, data, tipo, observações)
  - Integração com Google Maps/Geocoding
  - Estimativa de preço
  - Envio para banco de dados

- [ ] **Buscar Diaristas**
  - Listar diaristas disponíveis por região
  - Filtros (preço, avaliação, especialidades)
  - Perfil detalhado da diarista
  - Carrossel de fotos

- [ ] **Avaliar Diarista**
  - Tela de avaliação (1-5 estrelas)
  - Comentário opcional
  - Envio seguro ao Supabase

- [ ] **Chat**
  - Conversa com diarista em tempo real
  - Notificações de mensagens
  - Histórico de conversa

- [ ] **Perfil Avançado**
  - Upload de foto de perfil
  - Editar endereço padrão
  - Histórico de avaliações dadas
  - Métodos de pagamento

### Diarista
- [ ] **Aceitar/Recusar Solicitações**
  - Visualizar detalhes completos
  - Localização do cliente no mapa
  - Botões de aceitar/recusar
  - Confirmação com alert

- [ ] **Perfil Profissional Completo**
  - Editar descrição profissional
  - Foto de perfil
  - Preço por diária
  - Região de atendimento
  - Especialidades (checkboxes)
  - Ativar/Desativar profile

- [ ] **Gerenciar Serviços**
  - Atualizar status (em andamento → finalizada)
  - Cancelamento com até 24h
  - Rescheduling

- [ ] **Visualizar Avaliações**
  - Lista de avaliações recebidas
  - Média de estrelas
  - Comentários dos clientes
  - Período de análise

- [ ] **Chat**
  - Mesma implementação do cliente
  - Notificações
  - Histórico

---

## Funcionalidades Planejadas (Fase 3)

### Sistema de Notificações
- [ ] Notificação quando nova solicitação disponível
- [ ] Notificação quando solicitação é aceita
- [ ] Notificação quando serviço começa
- [ ] Notificação quando cliente envia mensagem
- [ ] Sistema de silent notifications

### Mapa e Localização
- [ ] Mapa interativo mostrando diaristas próximas
- [ ] Mapa de solicitações disponíveis para diarista
- [ ] Cálculo de distância
- [ ] Directions (rotas)
- [ ] Localização em tempo real do serviço

### Sistema de Pagamento
- [ ] Integração com Stripe ou PagSeguro
- [ ] Múltiplos métodos (cartão, Pix, boleto)
- [ ] Recibos digital
- [ ] Histórico de transações
- [ ] Reembolsos

### Cancelamento e Multas
- [ ] Política de cancelamento
- [ ] Multa por cancelamento em cima da hora
- [ ] Free cancellation até 24h antes
- [ ] Bloqueio após múltiplos cancelamentos

### Analytics e Dashboard
- [ ] Dashboard para diarista (ganhos, avaliação)
- [ ] Dashboard para cliente (gastos, histórico)
- [ ] Gráficos de uso
- [ ] Estatísticas

### Painel Web (Admin)
- [ ] Gerenciar usuários
- [ ] Visualizar relatórios
- [ ] Suporte ao usuário
- [ ] Analytics geral da plataforma
- [ ] Gerenciar pagamentos

---

## Funcionalidades em Análise

- [ ] Assinatura mensal para diaristas
- [ ] Programa de fidelidade para clientes
- [ ] Seguros de responsabilidade civil
- [ ] Verificação de antecedentes (background check)
- [ ] Agendamento recorrente
- [ ] Agendamento por IA (sugestões inteligentes)

---

## Detalhamento das Funcionalidades Core

### 1. Autenticação
- Email/Senha com validação
- Recuperação de senha (em implementação)
- Verificação de email (em implementação)
- Two-factor authentication (futuro)

### 2. Gerenciamento de Perfil
- `User` - Dados básicos (nome, email, foto)
- `DiaristaPerfil` - Dados profissionais
- `Cliente` - Dados específicos de cliente

### 3. Solicitação de Serviço
**Estados possíveis:**
1. **Pendente** - Criada, aguardando diarista aceitar
2. **Aceita** - Diarista aceitou
3. **Em Andamento** - Serviço começou
4. **Finalizada** - Serviço concluído
5. **Cancelada** - Cancelada por cliente ou diarista

### 4. Sistema de Avaliações
- Avaliação 1-5 estrelas
- Comentário textual
- Uma avaliação por conclusão de serviço
- Cálculo automático de média

### 5. Chat em Tempo Real
- Usa Supabase Realtime
- Criptografia fim-a-fim (futuro)
- Histórico persistente
- Sincronização com múltiplos dispositivos

---

## Performance e Otimizações

### Implementado
- ✅ Índices no banco de dados
- ✅ RLS para segurança
- ✅ Paginação em listas (futuro)
- ✅ Loading states
- ✅ Error handling

### Planejado
- [ ] Caching local com SQLite
- [ ] Offline-first architecture
- [ ] Lazy loading de imagens
- [ ] Compressão de dados
- [ ] CDN para assets

---

## Segurança

### Implementado
- ✅ Autenticação via Supabase Auth
- ✅ RLS em todas as tabelas
- ✅ Validação de entrada
- ✅ Proteção de credenciais

### Planejado
- [ ] Criptografia de dados sensíveis
- [ ] Blacklist de tokens
- [ ] Rate limiting
- [ ] CORS configurado
- [ ] Verificação de antecedentes

---

## Testes

### Unit Tests (Planejado)
- [ ] Validators
- [ ] Models serialization
- [ ] Services logic

### Widget Tests (Planejado)
- [ ] Form validation UI
- [ ] Navigation
- [ ] State management

### Integration Tests (Planejado)
- [ ] Fluxo de cadastro completo
- [ ] Fluxo de solicitação completo
- [ ] Fluxo de avaliação

---

## Métricas de Sucesso

### Para MVP
- ✅ Usuários podem se cadastrar e fazer login
- ✅ Clientes podem visualizar solicitações
- ✅ Diaristas podem visualizar serviços disponíveis
- ✅ Interface limpa e intuitiva

### Para Produção
- [ ] <2s tempo de carregamento da home
- [ ] <3 minutos para criar solicitação
- [ ] 99.5% uptime
- [ ] <1000ms latência de chat

---

## Glossário de Termos

| Termo | Descrição |
|-------|-----------|
| **Cliente** | Pessoa que solicita serviço de limpeza |
| **Diarista** | Profissional que oferece serviço de limpeza |
| **Solicitação** | Pedido de serviço criado por cliente |
| **Diária** | Serviço de limpeza em um dia específico |
| **RLS** | Row Level Security (segurança de banco de dados) |
| **MVP** | Minimum Viable Product (produto mínimo viável) |
| **UX** | User Experience (experiência do usuário) |
| **UI** | User Interface (interface do usuário) |

---

Última atualização: Janeiro 2024
