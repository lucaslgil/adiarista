# 📱 Configurando Genymotion com Flutter

## 🎯 O que é Genymotion?

Genymotion é um emulador Android rápido e profissional, muito mais leve que o emulador padrão do Android Studio. É perfeito para desenvolvimento Flutter!

## 📥 Instalação do Genymotion

### Opção 1: Genymotion Desktop (Recomendado)

1. **Baixe o Genymotion:**
   - Acesse: https://www.genymotion.com/download/
   - Escolha "Genymotion Desktop" (versão gratuita para uso pessoal)
   - Crie uma conta gratuita

2. **Instale o Genymotion:**
   - Execute o instalador baixado
   - Siga o assistente de instalação
   - **IMPORTANTE:** Marque a opção para instalar o VirtualBox junto (necessário)

3. **Configure sua primeira máquina virtual:**
   - Abra o Genymotion
   - Clique em "+" para adicionar novo dispositivo
   - Recomendado:
     - **Dispositivo:** Google Pixel 5
     - **Android:** 11.0 ou 12.0
     - **Tamanho:** ~2GB de disco
   - Clique em "Install"
   - Aguarde o download (pode demorar alguns minutos)

### Opção 2: Android Studio Emulator (Alternativa)

Se preferir usar o emulador padrão do Android Studio:

```powershell
# 1. Baixe Android Studio
https://developer.android.com/studio

# 2. Instale e abra Android Studio
# 3. Vá em: More Actions → Virtual Device Manager
# 4. Crie um novo dispositivo:
#    - Pixel 5
#    - Android 13 (Tiramisu)
#    - RAM: 2048MB
```

## 🚀 Conectando Flutter ao Genymotion

### Passo 1: Inicie o Emulador

```powershell
# Abra o Genymotion Desktop
# Clique em "Play" no dispositivo criado
# Aguarde o Android iniciar completamente
```

### Passo 2: Verifique a Detecção

```powershell
cd C:\Users\Lucas\Desktop\aDiarista\mobile
flutter devices
```

Você deve ver algo como:
```
Custom Phone (mobile) • 192.168.56.101:5555 • android-x86 • Android 11
```

### Passo 3: Execute o App no Emulador

```powershell
# Opção 1: Deixar Flutter escolher automaticamente
flutter run

# Opção 2: Especificar o dispositivo
flutter run -d <device-id>

# Exemplo:
flutter run -d 192.168.56.101:5555
```

## 🔧 Configuração Adicional (se o Flutter não detectar)

### Se o Genymotion não for detectado:

```powershell
# 1. Verifique a bridge do ADB
cd C:\Users\Lucas\AppData\Local\Android\Sdk\platform-tools
adb devices

# Se vazio, adicione manualmente:
adb connect 192.168.56.101:5555

# Verifique novamente:
adb devices
flutter devices
```

### Configurar Genymotion Shell:

```powershell
# No Genymotion Desktop:
# Settings → ADB → Use custom Android SDK tools
# Caminho: C:\Users\Lucas\AppData\Local\Android\Sdk
```

## ⚡ Vantagens do Genymotion

✅ **Muito mais rápido** que o emulador padrão  
✅ **Consome menos RAM** (~2GB vs 4GB+)  
✅ **Interface mais responsiva**  
✅ **Suporta sensores** (GPS, acelerômetro, câmera)  
✅ **Fácil de configurar** diferentes dispositivos  
✅ **Integração com ADB**

## 🆚 Comparação: Genymotion vs Web

| Recurso | Genymotion | Navegador |
|---------|-----------|-----------|
| Hot Reload | ⚡ Instantâneo | ⚡ Instantâneo |
| Sensores | ✅ Sim | ❌ Limitado |
| Câmera | ✅ Sim | ⚠️ Webcam |
| GPS | ✅ Simulado | ⚠️ Limitado |
| Notificações | ✅ Nativas | ❌ Não |
| Performance | 🚀 100% | 🐢 70% |
| Setup | ⚙️ Médio | ✅ Fácil |

## 📝 Comandos Úteis

```powershell
# Listar emuladores disponíveis
flutter emulators

# Iniciar emulador específico
flutter emulators --launch <emulator-id>

# Listar dispositivos conectados
flutter devices

# Executar no dispositivo específico
flutter run -d <device-id>

# Instalar app no emulador
flutter install -d <device-id>

# Ver logs do dispositivo
flutter logs -d <device-id>

# Limpar e reconstruir
flutter clean
flutter pub get
flutter run
```

## 🐛 Solução de Problemas

### Emulador não aparece no `flutter devices`

```powershell
# 1. Reinicie o ADB
adb kill-server
adb start-server

# 2. Conecte manualmente
adb connect 192.168.56.101:5555

# 3. Verifique licenças
flutter doctor --android-licenses
```

### App não instala

```powershell
# Limpe o build
flutter clean
flutter pub get

# Verifique permissões
adb shell pm list packages
```

### Emulador muito lento

1. **Aumente RAM do Genymotion:**
   - Settings → Configurações do dispositivo
   - Memory: 2048MB → 4096MB

2. **Habilite aceleração:**
   - Settings → VirtualBox
   - Habilite VT-x/AMD-V na BIOS

## 🎯 Próximos Passos Após Instalação

1. ✅ Instale o Genymotion
2. ✅ Crie um dispositivo virtual (Pixel 5)
3. ✅ Inicie o emulador
4. ✅ Execute `flutter devices`
5. ✅ Execute `flutter run`

O app irá compilar e instalar automaticamente no emulador!

---

**Dica:** Use Genymotion para testes Android e Web para testes rápidos de UI. Combine ambos para máxima produtividade! 🚀
