# 🧹 aDiarista - Aplicativo de Contratação de Diaristas

Um aplicativo mobile completo inspirado no Uber, porém voltado para conectar clientes com diaristas/faxineiras profissionais na região.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Stack Tecnológico](#stack-tecnológico)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Configuração do Supabase](#configuração-do-supabase)
- [Como Instalar e Rodar](#como-instalar-e-rodar)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Modelos de Dados](#modelos-de-dados)
- [Guia de Uso](#guia-de-uso)

---

## 👁️ Visão Geral

**aDiarista** é uma plataforma que conecta clientes que precisam de serviços de limpeza com diaristas disponíveis em sua região. O aplicativo oferece:

✅ Busca de diaristas disponíveis  
✅ Sistema de solicitação de serviços  
✅ Acompanhamento de status em tempo real  
✅ Avaliações e comentários  
✅ Interface moderna com tema claro/escuro  

---

## 🛠️ Stack Tecnológico

### Frontend Mobile
- **Flutter 3.0+** - Framework para desenvolvimento cross-platform (iOS/Android)
- **Provider** - Gerenciamento de estado
- **Go Router** - Navegação e roteamento
- **Google Fonts** - Tipografia moderna
- **Google Maps** - Localização e mapas (opcional)

### Backend
- **Supabase** - Backend as a Service (PostgreSQL + Auth)
- **PostgreSQL** - Banco de dados relacional
- **Realtime** - Notificações em tempo real

### Web (Painel Admin - Futuro)
- **React** - Framework web
- **Vercel** - Deploy

---

## 📁 Estrutura do Projeto

```
aDiarista/
│
├── mobile/                    # Aplicativo Flutter
│   ├── lib/
│   │   ├── config/           # Configurações (tema, roteamento, Supabase)
│   │   ├── models/           # Modelos de dados (User, Solicitacao, etc)
│   │   ├── services/         # Serviços (Auth, User/Database)
│   │   ├── screens/          # Telas do app
│   │   │   ├── auth/         # Login e Signup
│   │   │   ├── client/       # Telas do cliente
│   │   │   └── worker/       # Telas da diarista
│   │   ├── widgets/          # Componentes reutilizáveis
│   │   ├── utils/            # Utilitários (validators, helpers)
│   │   └── main.dart         # Entry point
│   ├── pubspec.yaml          # Dependências
│   └── README.md             # Documentação do app
│
├── web/                       # Painel web (React) - Futuro
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── services/
│   └── package.json
│
├── database/                  # Scripts SQL
│   └── migrations/
│       └── 001_initial_schema.sql
│
├── docs/                      # Documentação
│   ├── SETUP.md              # Guia de setup
│   ├── API.md                # Documentação da API
│   └── FEATURES.md           # Listas de funcionalidades
│
└── README.md                  # Você está aqui
```

---

## ⚙️ Configuração do Supabase

### 1. Criar Projeto no Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Faça login ou crie uma conta
3. Clique em "New Project"
4. Preencha os dados:
   - **Project Name**: `aDiarista`
   - **Database Password**: Use uma senha segura
   - **Region**: Escolha a mais próxima
5. Aguarde a criação (3-5 minutos)

### 2. Obter Credenciais

1. Após criar o projeto, vá para **Settings → API**
2. Copie:
   - **Project URL** (URL da API)
   - **Anon Key** (Chave pública)
   - **Service Key** (Chave privada - guarde bem!)

### 3. Executar SQL no Supabase

1. No Supabase, vá para **SQL Editor**
2. Clique em **New Query**
3. Cole todo o conteúdo do arquivo: `database/migrations/001_initial_schema.sql`
4. Clique em **Run** para executar

### 4. Configurar Autenticação

1. Vá para **Authentication → Providers**
2. Certifique-se de que **Email** está habilitado
3. Vá para **Authentication → Email Templates**
4. Configure templates personalizados (opcional)

### 5. Atualizar Credenciais no App

Abra `mobile/lib/config/supabase_config.dart` e substitua:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';
  static const String anonKey = 'sua-chave-anonima-aqui';
}
```

---

## 🚀 Como Instalar e Rodar

### Pré-requisitos

- **Flutter 3.0+** instalado (https://flutter.dev/docs/get-started/install)
- **Dart 2.17+** (vem com Flutter)
- **IDE**: VS Code com extensão Flutter ou Android Studio
- **Emulador ou Dispositivo**: Android/iOS

### Instalação

#### 1. Clonar o Repositório
```bash
git clone https://github.com/seu-usuario/adiarista.git
cd adiarista/mobile
```

#### 2. Instalar Dependências
```bash
flutter pub get
```

#### 3. Executar no Emulador/Dispositivo
```bash
flutter run
```

#### 4. Build para Produção (Opcional)
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## ✨ Funcionalidades Implementadas

### ✅ Fase 1 - MVP Inicial

#### Autenticação
- [x] Login com email/senha
- [x] Cadastro com tipo de usuário (cliente/diarista)
- [x] Logout
- [ ] Recuperação de senha
- [ ] Login com Google/Apple (futuro)

#### Cliente
- [x] Tela home (lista de solicitações)
- [x] Visualizar histórico
- [x] Perfil básico
- [ ] Criar solicitação de serviço
- [ ] Buscar diaristas disponíveis
- [ ] Avaliar diarista
- [ ] Chat com diarista
- [ ] Cancelar serviço

#### Diarista
- [x] Tela home (solicitações disponíveis)
- [x] Visualizar meus serviços
- [x] Perfil profissional
- [ ] Aceitar/Recusar solicitações
- [ ] Atualizar perfil (descrição, preço, região)
- [ ] Visualizar avaliações
- [ ] Chat com cliente
- [ ] Marcar como completo

### 🔄 Fase 2 - Expansão

- [ ] Mapa interativo com localização
- [ ] Notificações push
- [ ] Pagamento integrado
- [ ] Histórico completo com filtros
- [ ] Sistema de cancelamento com multa
- [ ] Agendamento de serviços futuros

### 🎯 Fase 3 - Premium

- [ ] Painel web (admin)
- [ ] Analytics e relatórios
- [ ] Integração com múltiplos métodos de pagamento
- [ ] API pública
- [ ] Versão empresarial

---

## 🏗️ Arquitetura

### Padrão de Arquitetura

O projeto segue padrões de **Clean Architecture** com separação clara de responsabilidades:

```
Presentation Layer (Screens)
         ↓
Business Logic Layer (Services)
         ↓
Data Layer (Models + Supabase)
```

### Camadas

#### 1. **Models** (`lib/models/`)
Define a estrutura de dados:
- `user.dart` - Usuário
- `diarista_perfil.dart` - Perfil da diarista
- `solicitacao.dart` - Solicitação de serviço
- `avaliacao.dart` - Avaliação

#### 2. **Services** (`lib/services/`)
Lógica de negócio e integração:
- `auth_service.dart` - Autenticação (Supabase Auth)
- `user_service.dart` - CRUD de usuários, solicitações e avaliações

#### 3. **Screens** (`lib/screens/`)
Interface com usuário:
- `auth/` - Login e Cadastro
- `client/` - Telas do cliente
- `worker/` - Telas da diarista

#### 4. **Config** (`lib/config/`)
Configuração geral:
- `theme.dart` - Tema visual (cores, tipografia)
- `router.dart` - Roteamento da navegação
- `supabase_config.dart` - Credenciais do Supabase

#### 5. **Widgets** (`lib/widgets/`)
Componentes reutilizáveis (em desenvolvimento)

#### 6. **Utils** (`lib/utils/`)
Funções utilitárias:
- `validators.dart` - Validação de email, CPF, etc

---

## 💾 Modelos de Dados

### Tabela: users
```sql
id              UUID (Primary Key)
nome            VARCHAR(255)
email           VARCHAR(255)
tipo_usuario    VARCHAR(50) -- 'cliente' ou 'diarista'
foto_perfil     TEXT
criado_em       TIMESTAMP
atualizado_em   TIMESTAMP
```

### Tabela: diaristas
```sql
user_id           UUID (Foreign Key)
descricao         TEXT
preco             DECIMAL(10,2)
avaliacao_media   DECIMAL(3,2)
regiao            VARCHAR(255)
especialidades    TEXT[]
ativo             BOOLEAN
criado_em         TIMESTAMP
atualizado_em     TIMESTAMP
```

### Tabela: solicitacoes
```sql
id              UUID (Primary Key)
cliente_id      UUID (Foreign Key)
diarista_id     UUID (Foreign Key - nullable)
status          VARCHAR(50) -- pendente|aceita|em_andamento|finalizada|cancelada
data_agendada   TIMESTAMP
endereco        VARCHAR(500)
descricao       TEXT
observacoes     TEXT
tipo_limpeza    VARCHAR(100)
preco_estimado  DECIMAL(10,2)
criado_em       TIMESTAMP
concluida_em    TIMESTAMP
```

### Tabela: avaliacoes
```sql
id              UUID (Primary Key)
cliente_id      UUID (Foreign Key)
diarista_id     UUID (Foreign Key)
nota            INTEGER -- 1 a 5
comentario      TEXT
criado_em       TIMESTAMP
```

---

## 📖 Guia de Uso

### Para Clientes

1. **Cadastro**: Abra o app → "Não tem conta? Cadastre-se" → Selecione "Cliente"
2. **Login**: Digite seu email e senha
3. **Criar Solicitação**: Clique no "+" → Preencha detalhes do serviço
4. **Acompanhar**: Veja o status na tela home
5. **Avaliar**: Após conclusão, deixe uma avaliação

### Para Diaristas

1. **Cadastro**: Abra o app → "Não tem conta? Cadastre-se" → Selecione "Diarista"
2. **Completar Perfil**: Vá para "Perfil" → Adicione descrição, preço, região
3. **Procurar Serviços**: Vá para "Disponíveis" → Veja solicitações pendentes
4. **Aceitar Trabalho**: Clique em "Aceitar" em uma solicitação
5. **Gerenciar**: Acompanhe status em "Meus Serviços"

---

## 🔐 Segurança

- ✅ Autenticação via Supabase Auth
- ✅ Row Level Security (RLS) no banco de dados
- ✅ Credenciais não expostas no código
- ✅ Validação de entrada de dados
- [ ] HTTPS obrigatório
- [ ] Criptografia de dados sensíveis (futuro)

---

## 🐛 Troubleshooting

### "Flutter not found"
```bash
# Adicione Flutter ao PATH ou use:
/usr/local/flutter/bin/flutter run
```

### "Connection to Supabase failed"
1. Verifique as credenciais em `supabase_config.dart`
2. Confirme que o projeto Supabase está criado
3. Verifique a conexão com internet

### "Authentication error"
1. SQL foi executado corretamente?
2. RLS está habilitado nas tabelas?
3. Verifique as políticas de segurança no Supabase

---

## 📚 Recursos Adicionais

- [Flutter Official Docs](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Provider State Management](https://pub.dev/packages/provider)
- [Go Router Navigation](https://pub.dev/packages/go_router)

---

## 📝 Roadmap

### Q1 2024
- [ ] Mapa integrado
- [ ] Notificações push
- [ ] Chat em tempo real

### Q2 2024
- [ ] Sistema de pagamento
- [ ] Painel web (admin)
- [ ] Analytics

### Q3 2024
- [ ] Versão empresarial
- [ ] API pública
- [ ] Expansão geográfica

---

## 👨‍💻 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um Fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 👥 Autores

- **Você**, Desenvolvedor Senior
- Inspirado em: Uber, iFood

---

## 💬 Suporte

Encontrou um bug? Tem uma sugestão?

- Abra uma [Issue](https://github.com/seu-usuario/adiarista/issues)
- Envie um email para: contato@adiarista.com.br

---

## 🎉 Agradecimentos

- Flutter Community
- Supabase Community
- Stack Overflow

---

**Feito com ❤️ para conectar clientes com profissionais de limpeza.**

Versão: 1.0.0 | Última atualização: Janeiro 2024
