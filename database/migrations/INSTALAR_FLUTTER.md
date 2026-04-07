# 📥 Como Instalar o Flutter no Windows

## 🎯 Opção 1: Instalação Manual (Recomendada)

### Passo 1: Download
1. Acesse: https://docs.flutter.dev/get-started/install/windows
2. Clique em "Download Flutter SDK"
3. Baixe o arquivo ZIP (aproximadamente 1.5GB)

### Passo 2: Extração
```powershell
# 1. Crie a pasta de destino
New-Item -ItemType Directory -Force -Path C:\src

# 2. Extraia o ZIP para C:\src\flutter
# Use o Windows Explorer ou:
Expand-Archive -Path "C:\Users\Lucas\Downloads\flutter_windows_*.zip" -DestinationPath C:\src
```

### Passo 3: Adicionar ao PATH
```powershell
# Execute no PowerShell como Administrador:
[System.Environment]::SetEnvironmentVariable(
    "Path",
    [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) + ";C:\src\flutter\bin",
    [System.EnvironmentVariableTarget]::User
)

# Reinicie o PowerShell após executar
```

### Passo 4: Verificar Instalação
```powershell
# Abra um NOVO terminal PowerShell e execute:
flutter --version
flutter doctor
```

### Passo 5: Aceitar Licenças Android
```powershell
flutter doctor --android-licenses
# Pressione 'y' para aceitar todas
```

---

## 🎯 Opção 2: Instalação com Winget (Windows 11)

```powershell
# Execute no PowerShell como Administrador:
winget install --id=Google.Flutter -e
```

---

## 🎯 Opção 3: Instalação com Chocolatey

```powershell
# 1. Instale Chocolatey (se não tiver):
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Instale o Flutter:
choco install flutter
```

---

## 📋 Dependências Necessárias

### Para Android:
1. **Android Studio**
   - Download: https://developer.android.com/studio
   - Instale com configurações padrão
   - Abra Android Studio → More Actions → SDK Manager
   - Instale Android SDK Platform-Tools

2. **Emulador Android**
   - Android Studio → More Actions → Virtual Device Manager
   - Crie um novo dispositivo (ex: Pixel 5)
   - Sistema: Android 13 (Tiramisu)

### Para Windows Desktop (Opcional):
1. **Visual Studio 2022**
   - Download: https://visualstudio.microsoft.com/downloads/
   - Selecione: "Desktop development with C++"
   - Componentes:
     - MSVC v142 ou superior
     - Windows 10 SDK
     - C++ CMake tools

### Para Web (Opcional):
- **Google Chrome** (já instalado em 99% dos PCs)

---

## ✅ Verificar Instalação

Execute e verifique se tudo está OK:

```powershell
flutter doctor -v
```

### Resultado Esperado:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version (Installed version of Windows is 10 or higher)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio - develop for Windows (opcional)
[!] Android Studio (version 2023.x) ← Avisos aqui são OK
[✓] Connected device (1 available)
```

### Problemas Comuns:

❌ **"cmdline-tools component is missing"**
```powershell
# Solução:
# 1. Abra Android Studio
# 2. Settings → Appearance & Behavior → System Settings → Android SDK
# 3. SDK Tools tab → Marque "Android SDK Command-line Tools"
# 4. Apply
```

❌ **"Some Android licenses not accepted"**
```powershell
flutter doctor --android-licenses
# Pressione 'y' várias vezes
```

---

## 🎯 Após Instalação

### 1. Configure um Emulador Android
```powershell
# Liste dispositivos:
flutter devices

# Se vazio, crie um emulador:
# 1. Abra Android Studio
# 2. More Actions → Virtual Device Manager
# 3. Create Device → Pixel 5 → Next
# 4. Download Android 13 → Next → Finish
# 5. Inicie o emulador (botão Play ▶️)
```

### 2. Teste o Flutter
```powershell
# Crie um projeto de teste:
flutter create teste_flutter
cd teste_flutter

# Rode no Chrome:
flutter run -d chrome

# Ou no emulador Android:
flutter run
```

### 3. Volte para o aDiarista
```powershell
cd C:\Users\Lucas\Desktop\aDiarista
.\SETUP_AUTOMATICO.ps1
```

---

## 📊 Requisitos de Sistema

### Mínimo:
- Windows 10 (64-bit) ou superior
- 4GB RAM
- 10GB espaço em disco (Flutter + Android)
- PowerShell 5.0 ou superior
- Git para Windows (https://git-scm.com)

### Recomendado:
- Windows 11
- 8GB RAM ou mais
- SSD com 20GB+ livres
- Processador quad-core

---

## 🆘 Ajuda Adicional

### Links Úteis:
- **Guia Oficial**: https://docs.flutter.dev/get-started/install/windows
- **Flutter Community**: https://flutter.dev/community
- **Stack Overflow**: Tag [flutter]

### Comandos de Diagnóstico:
```powershell
# Informações da instalação:
flutter --version
where flutter

# Verificação completa:
flutter doctor -v

# Listar dispositivos:
flutter devices

# Atualizar Flutter:
flutter upgrade

# Limpar cache:
flutter clean
```

---

## ✅ Checklist Completo

- [ ] Flutter SDK baixado e extraído em C:\src\flutter
- [ ] C:\src\flutter\bin adicionado ao PATH
- [ ] PowerShell reiniciado
- [ ] `flutter --version` funciona
- [ ] `flutter doctor` executado
- [ ] Android Studio instalado (para Android)
- [ ] Licenças Android aceitas (`flutter doctor --android-licenses`)
- [ ] Emulador Android criado (opcional)
- [ ] Visual Studio 2022 instalado (opcional, Windows Desktop)
- [ ] Chrome instalado (para web)
- [ ] Teste com `flutter create teste` passou

**Quando todos os itens estiverem ✅, volte e execute:**
```powershell
cd C:\Users\Lucas\Desktop\aDiarista
.\SETUP_AUTOMATICO.ps1
```

🚀 **Boa sorte!**
