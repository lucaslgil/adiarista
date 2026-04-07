# 🚀 Guia de Setup - aDiarista

## Pré-requisitos

Prima de tudo, você precisará ter instalado:

1. **Flutter 3.0+**
   - Download: https://flutter.dev/docs/get-started/install
   - Verificar: `flutter --version`

2. **Dart 2.17+**
   - Vem junto com Flutter
   - Verificar: `dart --version`

3. **Git**
   - Download: https://git-scm.com/
   - Verificar: `git --version`

4. **IDE (escolha uma)**
   - VS Code + Flutter Extension
   - Android Studio
   - IntelliJ IDEA

5. **Emulador/Dispositivo**
   - Android Emulator (via Android Studio)
   - iOS Simulator (Mac apenas)
   - Ou um dispositivo físico

---

## Passo 1: Configurar Supabase

### 1.1 Criar Projeto
1. Acesse https://supabase.com/dashboard
2. Clique "New Project"
3. Preencha:
   - **Project Name**: `adiarista`
   - **Password**: senha forte
   - **Region**: mais próxima de você
4. Aguarde 3-5 minutos

### 1.2 Obter Credenciais
1. Vá para **Settings → API**
2. Copie:
   - **Project URL**
   - **Anon Key**

### 1.3 Executar SQL
1. Vá para **SQL Editor**
2. Clique **New Query**
3. Cole o conteúdo de: `database/migrations/001_initial_schema.sql`
4. Clique **Run**

Pronto! Seu banco de dados está pronto.

---

## Passo 2: Configurar Flutter App

### 2.1 Clonar/Preparar Projeto
```bash
# Se estiver no repositório git
git clone https://github.com/seu-repo/adiarista.git
cd adiarista/mobile

# Se for criar do zero
mkdir adiarista
cd adiarista
```

### 2.2 Obter Dependências
```bash
flutter pub get
```

Isto baixará todas as dependências do `pubspec.yaml`.

### 2.3 Configurar Credenciais
Abra: `lib/config/supabase_config.dart`

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xyzabc.supabase.co'; // Sua URL
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIs...'; // Sua chave
}
```

Substitua pelos valores do Supabase.

### 2.4 Verificar Setup
```bash
flutter doctor
```

Todos os itens devem estar ✓ (com exceção do Xcode se não for Mac).

---

## Passo 3: Rodar o App

### 3.1 Listar Dispositivos Disponíveis
```bash
flutter devices
```

### 3.2 Rodar em Emulador
```bash
# Android
flutter run

# ou especificar:
flutter run -d emulator-5554

# iOS (Mac apenas)
flutter run -d "iPhone 14 Pro"
```

### 3.3 Rodar com Hot Reload
Uma vez que o app esteja rodando:
- Salve um arquivo e ele recarregará automaticamente
- `r` - hot reload
- `R` - hot restart
- `q` - quit

---

## Passo 4: Testar o App

### 4.1 Criar Conta
1. Na tela de login, clique "Não tem conta? Cadastre-se"
2. Selecione tipo (Cliente ou Diarista)
3. Preencha dados
4. Clique "Cadastrar"

### 4.2 Fazer Login
1. Volte para login
2. Digite email e senha
3. Clique "Entrar"

### 4.3 Explorar
- Cliente: veja a home e histórico
- Diarista: veja solicitações disponíveis

---

## Passo 5: Build para Produção

### 5.1 Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk
```

### 5.2 Android App Bundle (Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5.3 iOS (Mac)
```bash
flutter build ios --release
# Output: build/ios/ipa/
```

---

## Troubleshooting

### Problema: "flutter: not found"
**Solução:**
```bash
# Adicione Flutter ao PATH (Linux/Mac)
export PATH="$PATH:`pwd`/flutter/bin"

# Ou use o caminho completo
/usr/local/flutter/bin/flutter run
```

### Problema: "Connection refused"
**Solução:**
1. Verifique a URL do Supabase
2. Verifique a chave Anon
3. Verifique a conexão com internet
4. Teste em: https://seu-projeto.supabase.co/rest/v1/

### Problema: "Compilation failed"
**Solução:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problema: "Gradle build failed"
**Solução:**
```bash
# Android
rm -rf android/app/build
flutter pub get
flutter run
```

### Problema: "Port 8080 in use"
**Solução:**
```bash
# Kill process na porta 8080 (Mac/Linux)
sudo lsof -ti:8080 | xargs kill -9

# Ou use outra porta
flutter run --host 127.0.0.1 --port 8081
```

### Problema: "Auth error - invalid credentials"
**Solução:**
1. Verifique que a tabela `users` existe no Supabase
2. Execute novamente o SQL de setup
3. Verifique as RLS policies

---

## Estrutura de Pastas Explicada

```
mobile/
├── lib/                  # Código fonte
│   ├── config/          # Configurações globais
│   │   ├── supabase_config.dart
│   │   ├── theme.dart   # Cores, tipografia
│   │   └── router.dart  # Rotas de navegação
│   ├── models/          # Estruturas de dados
│   │   ├── user.dart
│   │   ├── solicitacao.dart
│   │   └── ...
│   ├── services/        # Lógica de negócio
│   │   ├── auth_service.dart
│   │   └── user_service.dart
│   ├── screens/         # Telas do app
│   │   ├── auth/        # Login, Signup
│   │   ├── client/      # Home cliente
│   │   └── worker/      # Home diarista
│   ├── utils/           # Funcionalidades auxiliares
│   └── main.dart        # Entry point
├── pubspec.yaml         # Dependências
└── README.md            # Documentação
```

---

## Dicas de Desenvolvimento

### Hot Reload
- Salve um arquivo para recarregar
- Útil para alterações na UI
- Não funciona com mudanças na main()

### Flutter Inspector
- F12 em VS Code
- Debuggy widget tree
- Inspecione props

### DevTools
```bash
flutter pub global activate devtools
devtools
# Acesse: http://localhost:9100
```

### Logs
```bash
flutter logs
# ou com filtro:
flutter logs --driver-port=8888
```

### Debugging
- Adicione `debugPrint('valor');`
- Use breakpoints no VS Code/Android Studio
- Veja o console do emulador

---

## Próximos Passos

1. ✅ Setup completado
2. 📦 Adicione mais features
3. 🧪 Escreva testes
4. 📱 Build para produção
5. 🚀 Deploy na Google Play/App Store

---

## Recursos Úteis

- [Flutter Docs](https://flutter.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Dart Docs](https://dart.dev/guides)
- [Stack Overflow - Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)

---

## Suporte

Encontrou algum problema?
1. Verifique o [README.md](../README.md)
2. Veja [FEATURES.md](../FEATURES.md)
3. Abra uma issue no GitHub
4. Envie um email para: contato@adiarista.com.br

---

Última atualização: Janeiro 2024

Sucesso! 🚀
