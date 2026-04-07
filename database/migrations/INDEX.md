# 📑 Índice de Arquivos - aDiarista

## Guia Rápido de Navegação do Projeto

### 📱 Documentação Principal

| Arquivo | Descrição | Leitura Recomendada |
|-----------|-----------|------------------|
| [README.md](README.md) | Visão geral completa do projeto | ⭐⭐⭐⭐⭐ |
| [SETUP.md](SETUP.md) | Guia passo-a-passo para configurar | ⭐⭐⭐⭐⭐ |
| [FEATURES.md](FEATURES.md) | Lista detalhada de funcionalidades | ⭐⭐⭐⭐ |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Diagrama de arquitetura e fluxos | ⭐⭐⭐⭐ |
| [TESTING.md](TESTING.md) | Como escrever e executar testes | ⭐⭐⭐ |
| [CHECKLIST.md](CHECKLIST.md) | Checklist de implementação | ⭐⭐⭐ |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Padrões de código *criar* | ⭐⭐ |

---

### 📁 Estrutura de Pastas

```
aDiarista/
│
├── 📖 DOCUMENTAÇÃO
│   ├── README.md ..................... Guia principal
│   ├── SETUP.md ..................... Configuração
│   ├── FEATURES.md .................. Funcionalidades
│   ├── ARCHITECTURE.md .............. Arquitetura
│   ├── TESTING.md ................... Testes
│   ├── CHECKLIST.md ................. Implementação
│   └── INDEX.md ..................... Este arquivo
│
├── 🚀 MOBILE (Flutter)
│   │
│   ├── pubspec.yaml ................. Dependências
│   ├── .gitignore ................... Arquivos ignorados
│   ├── project.yaml ................. Configuração do projeto
│   │
│   └── lib/
│       │
│       ├── main.dart ................ Entry point (COMECE AQUI)
│       │
│       ├── 🎨 config/
│       │   ├── theme.dart .......... Cores, tipografia
│       │   ├── router.dart ......... Navegação
│       │   └── supabase_config.dart  ⚠️ EDITE AQUI com suas credenciais
│       │
│       ├── 📦 models/
│       │   ├── user.dart .......... Modelo de usuário
│       │   ├── diarista_perfil.dart Modelo de diarista
│       │   ├── solicitacao.dart ... Modelo de solicitação
│       │   └── avaliacao.dart .... Modelo de avaliação
│       │
│       ├── 🔧 services/
│       │   ├── auth_service.dart ... Autenticação
│       │   └── user_service.dart ... Database & CRUD
│       │
│       ├── 📱 screens/
│       │   ├── auth/
│       │   │   ├── login_screen.dart ........ Tela de login
│       │   │   └── signup_screen.dart ...... Tela de cadastro
│       │   ├── client/
│       │   │   └── home_client_screen.dart  Home do cliente
│       │   └── worker/
│       │       └── home_worker_screen.dart Home da diarista
│       │
│       ├── 🎁 widgets/
│       │   └── custom_widgets.dart ... Componentes reutilizáveis
│       │
│       └── 🛠️ utils/
│           ├── constants.dart ...... Constantes do app
│           ├── validators.dart .... Validações
│           └── extensions.dart .... Extensões úteis
│
├── 🗄️ DATABASE
│   └── migrations/
│       └── 001_initial_schema.sql .. ⚠️ EXECUTE NO SUPABASE
│
├── 🌐 WEB (Futuro - React)
│   └── src/
│       ├── components/
│       ├── pages/
│       └── services/
│
└── 📝 CONFIG FILES
    ├── .env.example ............... Template de variáveis
    ├── project.yaml ............... Config do projeto
    └── .gitignore ................. Arquivos a ignorar
```

---

### 🚀 Quick Start

**1. Comece lendo aqui:**
- [ ] [README.md](README.md) - Entenda o projeto (10 min)
- [ ] [SETUP.md](SETUP.md) - Configure tudo (20 min)

**2. Depois configure:**
- [ ] Criar conta no Supabase
- [ ] Executar SQL do banco
- [ ] Editar credenciais em `lib/config/supabase_config.dart`

**3. Em seguida rode:**
```bash
cd mobile
flutter pub get
flutter run
```

**4. Entenda a arquitetura:**
- [ ] [ARCHITECTURE.md](ARCHITECTURE.md) - Como funciona

**5. Comece a desenvolver:**
- [ ] Escolha uma feature em [FEATURES.md](FEATURES.md)
- [ ] Consulte [CHECKLIST.md](CHECKLIST.md) para próximos passos

---

### 📚 Estrutura de Aprendizado

```
INICIANTE
├── README.md ..................... O que é o projeto?
├── SETUP.md ..................... Como configurar?
└── flutter run .................. Rodar localmente
          ↓
INTERMEDIÁRIO
├── ARCHITECTURE.md .............. Como funciona?
├── FEATURES.md .................. O que falta?
└── Explorar o código
          ↓
AVANÇADO
├── TESTING.md ................... Como testar?
├── Escrever testes
├── Otimizar performance
└── Deploy em produção
```

---

### 🎯 Arquivos por Responsabilidade

#### **Autenticação**
- `lib/services/auth_service.dart` - Lógica de auth
- `lib/screens/auth/login_screen.dart` - Tela de login
- `lib/screens/auth/signup_screen.dart` - Tela de cadastro
- `lib/config/supabase_config.dart` - Credenciais
- `database/migrations/001_initial_schema.sql` - Tabelas

#### **Cliente**
- `lib/screens/client/home_client_screen.dart` - Home
- `lib/models/solicitacao.dart` - Dados de solicitação
- `lib/services/user_service.dart` - Operações de cliente

#### **Diarista**
- `lib/screens/worker/home_worker_screen.dart` - Home
- `lib/models/diarista_perfil.dart` - Dados de diarista
- `lib/services/user_service.dart` - Operações de diarista

#### **Compartilhado**
- `lib/config/theme.dart` - Design visual
- `lib/config/router.dart` - Navegação
- `lib/models/user.dart` - Usuário
- `lib/utils/extensions.dart` - Utilitários
- `lib/widgets/custom_widgets.dart` - Componentes

#### **Configuração**
- `pubspec.yaml` - Dependências
- `.env.example` - Variáveis de ambiente
- `project.yaml` - Meta do projeto
- `.gitignore` - Arquivos ignorados

---

### 📋 Onde Fazer Mudanças Comuns

#### "Quero mudar as cores"
→ Edite `lib/config/theme.dart`

#### "Quero adicionar uma tela nova"
→ Crie em `lib/screens/` e adicione rota em `lib/config/router.dart`

#### "Quero adicionar um serviço"
→ Crie em `lib/services/`

#### "Quero adicionar um modelo"
→ Crie em `lib/models/`

#### "Quero mudar a estrutura do banco"
→ Execute novo SQL no Supabase e atualize modelos/serviços

#### "Quero adicionar dependência"
→ `flutter pub add nome_pacote` e edite `pubspec.yaml`

---

### 🔑 Credenciais (IMPORTANTE!)

**Nunca commit seus .env com credenciais!**

1. Copie `.env.example` para `.env`
2. Preencha com suas credenciais
3. `.env` está no `.gitignore` (seguro)

```bash
# Arquivo .env (nunca commitar!)
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima
```

---

### 🧪 Testes

**Onde os testes vão:**
```
test/
├── models/
├── services/
├── utils/
├── widgets/
└── integration/
```

**Como rodar:**
```bash
flutter test
flutter test test/utils/validators_test.dart
flutter test --coverage
```

---

### 🚀 Deploy

#### Android
```bash
flutter build apk --release
# Ou para Google Play:
flutter build appbundle --release
```

#### iOS (Mac)
```bash
flutter build ios --release
```

---

### 🐛 Debugging

**Arquivo Problemas Comuns:**
- Consulte [SETUP.md - Troubleshooting](SETUP.md#troubleshooting)

**Logs em tempo real:**
```bash
flutter logs
```

**Debugger:**
- Pause em breakpoints no VS Code/Android Studio
- Use `debugPrint()` no código

---

### 📱 Dependências Principais

| Pacote | Para que serve | Arquivo |
|--------|---------------|---------|
| supabase_flutter | Backend & Database | `lib/services/` |
| provider | Gerenciamento de estado | `lib/main.dart` |
| go_router | Navegação | `lib/config/router.dart` |
| google_fonts | Tipografia | `lib/config/theme.dart` |
| email_validator | Validar emails | `lib/utils/validators.dart` |

Ver mais em `pubspec.yaml`

---

### 🎓 Aprender Mais

**Flutter & Dart:**
- https://flutter.dev/docs
- https://dart.dev/guides

**Supabase:**
- https://supabase.com/docs
- https://github.com/supabase/supabase

**UI/Design:**
- Material Design 3
- Google Fonts

**State Management:**
- Provider Documentation
- BLoC pattern (futuro)

**Navegação:**
- Go Router Docs

---

### 💻 Comandos Úteis

```bash
# Setup inicial
flutter pub get

# Rodar app
flutter run
flutter run -d "iPhone 14 Pro"  # iOS específico

# Build
flutter build apk --release
flutter build ios --release

# Testes
flutter test
flutter test --coverage

# Clean
flutter clean

# Analisar código
flutter analyze

# Format código
dart format lib/

# Ver dispositivos
flutter devices

# Hot reload
r
R  # hot restart
q  # quit
```

---

### 📊 Estatísticas do Projeto

- **Linhas de código:** ~2000+ (inicial)
- **Arquivos criados:** 20+
- **Telas implementadas:** 4
- **Models:** 4
- **Services:** 2
- **Documentação:** 2000+ linhas

---

### ✅ Checklist Rápido

- [x] Estrutura criada
- [x] Config básica
- [x] Modelos definidos
- [x] Serviços implementados
- [x] Telas de auth
- [x] Telas home
- [x] SQL database
- [x] Documentação completa
- [ ] Testes escritos (próximo passo)
- [ ] Features adicionadas (próximo passo)

---

### 🤝 Suporte

**Dúvidas sobre código?**
→ Consulte o arquivo correspondente e adicione comentários

**Erro ao rodar?**
→ Veja [SETUP.md - Troubleshooting](SETUP.md#troubleshooting)

**Bug encontrado?**
→ Abra uma issue no GitHub

---

**Última atualização:** Janeiro 2024

**Status:** 🟢 Pronto para desenvolvimento

Sucesso no seu projeto! 🚀
