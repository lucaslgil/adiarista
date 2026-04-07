# 🚀 Guia Rápido - aDiarista

## ⚡ Setup Automático (RECOMENDADO)

### Windows PowerShell:
```powershell
# Execute na pasta raiz do projeto:
.\SETUP_AUTOMATICO.ps1
```

**O que o script faz:**
1. ✅ Verifica se Flutter está instalado
2. ✅ Valida dependências (flutter doctor)
3. ✅ Instala pacotes do projeto (flutter pub get)
4. ✅ Verifica configuração do Supabase
5. ✅ Lista dispositivos disponíveis
6. ✅ Pergunta se quer rodar o app

---

## 📱 Rodar o App Manualmente

### Pré-requisitos:
- ✅ Flutter SDK instalado
- ✅ Android Studio OU Emulador OU Dispositivo físico conectado

### Comandos:
```bash
# 1. Entre na pasta mobile
cd mobile

# 2. Instale dependências
flutter pub get

# 3. Liste dispositivos disponíveis
flutter devices

# 4. Rode o app
flutter run

# OU especifique um dispositivo:
flutter run -d chrome          # Web
flutter run -d windows         # Windows Desktop
flutter run -d <device-id>     # Android/iOS
```

---

## 🔧 Comandos Úteis

### Desenvolvimento:
```bash
# Hot reload (durante execução): pressione 'r'
# Hot restart: pressione 'R'
# Abrir DevTools: pressione 'd'
# Parar app: pressione 'q'

# Rodar em modo release (performance real):
flutter run --release

# Rodar com logs detalhados:
flutter run -v

# Limpar cache e rebuild:
flutter clean
flutter pub get
flutter run
```

### Build:
```bash
# Android APK:
flutter build apk

# Android App Bundle (Google Play):
flutter build appbundle

# Windows Desktop:
flutter build windows
```

### Testes:
```bash
# Rodar todos os testes:
flutter test

# Rodar testes específicos:
flutter test test/models/user_test.dart

# Testes com coverage:
flutter test --coverage
```

### Análise de Código:
```bash
# Analisar código:
flutter analyze

# Formatar código:
flutter format .

# Verificar versão:
flutter --version

# Atualizar Flutter:
flutter upgrade
```

---

## 📋 Checklist de Primeiro Uso

### 1️⃣ Instalação Flutter (se necessário)
- [ ] Baixar: https://docs.flutter.dev/get-started/install/windows
- [ ] Extrair em `C:\src\flutter`
- [ ] Adicionar ao PATH: `C:\src\flutter\bin`
- [ ] Reiniciar terminal
- [ ] Executar: `flutter doctor`
- [ ] Instalar dependências indicadas pelo doctor

### 2️⃣ Configuração do Projeto
- [x] Banco de dados criado no Supabase ✅
- [x] Credenciais configuradas em `supabase_config.dart` ✅
- [ ] Dependências instaladas (`flutter pub get`)
- [ ] Sem erros no `flutter analyze`

### 3️⃣ Dispositivo/Emulador
- [ ] Android Studio instalado (para Android)
- [ ] Emulador Android criado e rodando
- [ ] OU dispositivo físico conectado via USB
- [ ] OU navegador web (Chrome) disponível

### 4️⃣ Primeiro Teste
- [ ] App iniciado sem erros
- [ ] Tela de login exibida
- [ ] Criar conta de teste (tipo: cliente)
- [ ] Fazer login
- [ ] Verificar dados no Supabase (Table Editor)

---

## 🐛 Problemas Comuns

### "flutter: command not found"
**Solução:**
```powershell
# Adicione ao PATH:
[System.Environment]::SetEnvironmentVariable(
    "Path",
    $env:Path + ";C:\src\flutter\bin",
    [System.EnvironmentVariableTarget]::User
)

# Reinicie o PowerShell
```

### "No devices found"
**Soluções:**
1. **Android**: Abra Android Studio → AVD Manager → Start emulador
2. **Web**: O Chrome está instalado? Use `flutter run -d chrome`
3. **Windows**: Use `flutter run -d windows`
4. **Físico**: Habilite modo desenvolvedor no dispositivo

### Erros de compilação
```bash
# Limpe e reconstrua:
flutter clean
flutter pub get
flutter run
```

### Erro "Supabase connection refused"
- Verifique se as credenciais estão corretas em `supabase_config.dart`
- Teste a URL no navegador: https://tjenoowimxcsenuzpcyf.supabase.co
- Verifique conexão com internet

---

## 📚 Estrutura do Projeto

```
mobile/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── config/
│   │   ├── supabase_config.dart    # ⚠️ Credenciais aqui
│   │   ├── theme.dart              # Design system
│   │   └── router.dart             # Navegação
│   ├── models/                      # Data models
│   ├── services/                    # API/Database
│   ├── screens/                     # UI screens
│   │   ├── auth/                   # Login/Signup
│   │   ├── client/                 # Cliente screens
│   │   └── worker/                 # Diarista screens
│   ├── widgets/                     # Reusable components
│   └── utils/                       # Helpers
├── pubspec.yaml                     # Dependências
└── test/                            # Testes automatizados
```

---

## 🎯 Próximos Passos

### Fase 1: Testar MVP ✅
1. [x] Criar conta (cliente)
2. [x] Fazer login
3. [ ] Criar solicitação (falta implementar tela)
4. [ ] Buscar diaristas (falta implementar)
5. [x] Logout

### Fase 2: Implementar Telas Faltantes
1. [ ] Tela de criar solicitação
2. [ ] Tela de buscar diaristas
3. [ ] Tela de perfil de diarista
4. [ ] Tela de avaliação
5. [ ] Tela de editar perfil

### Fase 3: Features Avançadas
1. [ ] Chat em tempo real
2. [ ] Notificações push
3. [ ] Integração com mapas
4. [ ] Sistema de pagamento

---

## 🆘 Suporte

### Recursos:
- **Flutter Docs**: https://docs.flutter.dev
- **Supabase Docs**: https://supabase.com/docs
- **Projeto README**: [README.md](README.md)
- **Arquitetura**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **Features**: [FEATURES.md](FEATURES.md)

### Comandos de Ajuda:
```bash
flutter help            # Ajuda geral
flutter doctor -v      # Diagnóstico detalhado
flutter devices        # Listar dispositivos
flutter pub outdated   # Verificar updates
```

---

## ✅ Status Atual

| Item | Status |
|------|--------|
| Banco de dados | ✅ Criado |
| Credenciais | ✅ Configuradas |
| Modelos de dados | ✅ Implementados |
| Serviços (API) | ✅ Implementados |
| Telas de autenticação | ✅ Implementadas |
| Telas home | ✅ Implementadas |
| Flutter instalado | ⚠️ Verificar |
| Dependências instaladas | ⚠️ Executar script |

**Pronto para começar!** Execute `.\SETUP_AUTOMATICO.ps1` 🚀
