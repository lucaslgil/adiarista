# 🚀 Guia de Configuração do Genymotion

## 📋 Pré-requisitos Instalados
- ✅ VirtualBox 7.2.6
- ✅ Genymotion 3.9.0 (instalando...)
- ✅ Flutter SDK 3.27.1

---

## 🔧 Passo 1: Configuração Inicial

### 1.1 Criar Conta Genymotion (Gratuita)
1. Acesse: https://www.genymotion.com/account/create/
2. Escolha **"Personal Use"** (gratuito)
3. Preencha seus dados e confirme o email

### 1.2 Login no Genymotion Desktop
1. Abra **Genymotion Desktop** (procure no menu Iniciar)
2. Faça login com suas credenciais
3. Aceite os termos de uso

---

## 📱 Passo 2: Criar Device Virtual

### 2.1 Adicionar novo dispositivo
1. Clique em **"+"** ou "Add a new device"
2. Escolha um dispositivo popular para Flutter:

**Recomendados para teste:**
```
📱 Google Pixel 6
   - Android 13.0 (API 33)
   - 1080 x 2400
   - 6GB RAM
   
📱 Samsung Galaxy S21
   - Android 12.0 (API 31)  
   - 1080 x 2400
   - 8GB RAM
```

3. Clique em **"Install"** para baixar a imagem do Android
4. Aguarde o download completar (~500MB - 1GB)
5. Nomeie o dispositivo (ex: "Pixel 6 - aDiarista")

### 2.2 Iniciar o Emulador
1. Selecione o dispositivo criado
2. Clique em **"Start"**
3. Aguarde o Android iniciar (primeira vez pode demorar 2-3 minutos)

---

## 🔗 Passo 3: Conectar Flutter ao Genymotion

### 3.1 Verificar ADB (Android Debug Bridge)
No PowerShell, execute:
```powershell
cd C:\Users\Lucas\Desktop\aDiarista\mobile
flutter doctor
```

### 3.2 Verificar dispositivos conectados
```powershell
flutter devices
```

Você deve ver algo como:
```
Genymotion Pixel 6 (mobile) • 192.168.56.101:5555 • android-arm64 • Android 13 (API 33)
```

### 3.3 Executar app no Genymotion
```powershell
# Rodar no Genymotion (detectado automaticamente)
flutter run

# Ou especificar o device ID
flutter run -d <device-id>
```

---

## ⚙️ Passo 4: Configurações Avançadas

### 4.1 Habilitar Performance
No Genymotion Desktop:
1. Clique no ⚙️ (Settings)
2. Vá em **"ADB"**
3. Marque **"Use custom Android SDK tools"**
4. Apontar para: `C:\Users\Lucas\AppData\Local\Android\Sdk`
   (ou onde seu Flutter SDK armazena o Android SDK)

### 4.2 Instalar Google Play Services (opcional)
1. Com o emulador rodando, arraste o arquivo `.apk` de Open GApps
2. Ou use o widget **"Opem GApps"** no Genymotion
3. Reinicie o dispositivo virtual

### 4.3 Configurar Rede
- Por padrão, o Genymotion usa **Bridge Network**
- Seu app terá acesso à internet automaticamente
- Para testar Supabase local, use o IP da máquina host: `10.0.3.2`

---

## 🐛 Troubleshooting Comum

### Problema: "flutter devices" não detecta Genymotion
**Solução:**
```powershell
# Conectar manualmente via ADB
cd C:\src\flutter\bin\cache\artifacts\engine\android-arm64
.\adb.exe connect 192.168.56.101:5555
```

### Problema: Emulador muito lento
**Soluções:**
1. Aumentar RAM do device (Settings → Configure → RAM)
2. Desabilitar animações no Android:
   - Settings → Developer Options → Window/Transition/Animator scale → 0.5x
3. Habilitar virtualização no BIOS (VT-x/AMD-V)

### Problema: "VirtualBox error"
**Solução:**
```powershell
# Verificar se VirtualBox está instalado
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version

# Reinstalar se necessário
winget install Oracle.VirtualBox
```

### Problema: App não atualiza com Hot Reload
**Solução:**
- Genymotion suporta hot reload normalmente
- Se não funcionar, use: `R` (hot restart completo)
- Ou recompile: `flutter run`

---

## 🎯 Atalhos Úteis no Emulador

| Ação | Atalho |
|------|--------|
| Tela inicial | Ctrl + Home |
| Voltar | Ctrl + Backspace |
| Menu Apps | Ctrl + Shift + L |
| Screenshot | Ctrl + S |
| Rotacionar tela | Ctrl + ← / → |
| Volume + | Ctrl + ↑ |
| Volume - | Ctrl + ↓ |

---

## 📊 Comparação: Genymotion vs Android Studio Emulator

| Recurso | Genymotion | Android Studio |
|---------|------------|----------------|
| **Velocidade** | ⚡⚡⚡⚡⚡ Muito rápido | ⚡⚡⚡ Médio |
| **Uso de RAM** | 🟢 Leve (2-4GB) | 🟠 Pesado (4-8GB) |
| **Setup** | 🟢 Fácil (VirtualBox) | 🟠 Complexo (HAXM/SDK) |
| **Google Play** | 🟡 Requer install | ✅ Nativo |
| **Dispositivos** | 🟡 Limitado (free) | ✅ Muitos |
| **Flutter Hot Reload** | ✅ Funciona | ✅ Funciona |

**Recomendação**: Genymotion é ideal para desenvolvimento rápido e testes. Para testes avançados (Google Play Services, GPS, etc.), considere Android Studio emulator ou dispositivo físico.

---

## 🚀 Próximos Passos

1. ✅ Instalar Genymotion
2. ⬜ Criar conta gratuita
3. ⬜ Baixar device virtual (Pixel 6 ou Galaxy S21)
4. ⬜ Iniciar emulador
5. ⬜ Executar `flutter run` no aDiarista
6. ⬜ Testar login screen no emulador Android
7. ⬜ Verificar hot reload funcionando

---

## 📚 Recursos Adicionais

- **Documentação oficial**: https://docs.genymotion.com/desktop/
- **Flutter + Genymotion**: https://flutter.dev/docs/get-started/install/windows#android-setup
- **Suporte Genymotion**: https://www.genymotion.com/help/

**Status da Instalação:** ✅ CONCLUÍDO

---

## ✅ Instalação Automática Concluída

Os seguintes componentes foram instalados automaticamente:

- ✅ **VirtualBox 7.2.6** - Gerenciador de máquinas virtuais
- ✅ **Genymotion 3.9.0** - Emulador Android rápido
- ✅ **Java JDK 17** - Necessário para Android SDK
- ✅ **Android SDK Tools** - Command line tools, platform-tools, build-tools
- ✅ **Android API 33** - Android 13 para desenvolvimento
- ✅ **Flutter Android Toolchain** - Configurado e funcionando

### 🚀 Comando Rápido para Testar

```powershell
# 1. Abra o Genymotion e crie um device (Pixel 6 - Android 13)
# 2. Inicie o device virtual
# 3. Execute no terminal:

cd C:\Users\Lucas\Desktop\aDiarista\mobile
flutter devices  # Deve mostrar o device Genymotion
flutter run      # Roda o app aDiarista no emulador
```

### 📍 variáveis de Ambiente Configuradas

```
ANDROID_HOME      = C:\Users\Lucas\AppData\Local\Android\Sdk
ANDROID_SDK_ROOT  = C:\Users\Lucas\AppData\Local\Android\Sdk  
JAVA_HOME         = C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot
```

### 🎮 Atalhos do Emulador Genymotion

| Ação | Atalho |
|------|--------|
| Home | Ctrl + Home |
| Voltar | Ctrl + Backspace |
| Apps | Ctrl + Shift + L |
| Screenshot | Ctrl + S |
| Rotacionar | Ctrl + ← / → |
| Volume +/- | Ctrl + ↑ / ↓ |

### 💡 Dicas Importantes

1. **Primeira vez**: Crie conta gratuita em https://www.genymotion.com/account/create/
2. **Device recomendado**: Google Pixel 6 com Android 13 (API 33)
3. **Hot Reload**: Funciona normalmente no Genymotion
4. **Performance**: Muito mais rápido que o emulador padrão do Android Studio
5. **Rede**: Emulador tem acesso direto à internet

---

**Status da Instalação:** ✅ CONCLUÍDO - Pronto para uso!
