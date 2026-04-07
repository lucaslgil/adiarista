# 🔧 Genymotion - Solução de Problemas

## ❌ Erro: "Unable to start the virtual device - DHCP could not assign IP"

### 🔴 Problema
```
The virtual device did not get any IP address.
The VirtualBox DHCP server could not assign an IP address to the virtual device.
```

### ✅ SOLUÇÃO RÁPIDA (Recomendada)

#### Mudar para modo Bridge:

1. **No Genymotion Desktop**, selecione seu device virtual (NÃO clique em Start ainda)

2. Clique com botão **direito** → **Configure** (ou clique no ícone ⚙️)

3. Na janela de configuração, vá em **Network**

4. Mude as configurações:
   ```
   Network mode: Bridge
   Adapter: [Selecione sua placa de rede ativa - Wi-Fi ou Ethernet]
   ```

5. Clique em **OK**

6. Agora clique em **Start** para iniciar o device

7. ✅ O emulador deve iniciar normalmente com IP da sua rede local

---

## 🔄 Solução Alternativa 1: Recriar o Device

Se a mudança para Bridge não funcionar:

1. **Delete o device atual**:
   - Botão direito no device → Delete
   
2. **Crie um novo device**:
   - Botão `+` (Add a new device)
   - Escolha: **Google Pixel 6 - Android 13 (API 33)**
   - Durante o wizard de criação, configure:
     - Network: **Bridge**
     - RAM: 2048 MB (ou mais se tiver disponível)

3. Baixe a imagem e inicie

---

## 🔄 Solução Alternativa 2: Corrigir DHCP do VirtualBox

Se preferir manter o modo NAT, execute estes comandos no PowerShell (como Administrador):

```powershell
# Fechar Genymotion
Stop-Process -Name "genymotion" -Force -ErrorAction SilentlyContinue

# Reconfigurar DHCP
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" dhcpserver remove --netname "HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter"

& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" dhcpserver add --netname "HostInterfaceNetworking-VirtualBox Host-Only Ethernet Adapter" --ip 192.168.56.100 --netmask 255.255.255.0 --lowerip 192.168.56.101 --upperip 192.168.56.254 --enable

# Reconfigurar interface
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter" --ip 192.168.56.1 --netmask 255.255.255.0

# Reabrir Genymotion
Start-Process "C:\Program Files\Genymobile\Genymotion\genymotion.exe"
```

Depois, tente iniciar o device no modo NAT novamente.

---

## 🌐 Diferença entre Bridge e NAT

| Modo | Descrição | Prós | Contras |
|------|-----------|------|---------|
| **Bridge** | Emulador conecta direto na sua rede | ✅ Mais estável<br>✅ Não depende DHCP VirtualBox<br>✅ IP real da rede | ⚠️ Expõe emulador na rede local |
| **NAT** | Emulador usa rede virtual VirtualBox | ✅ Mais isolado<br>✅ Não expõe na rede | ❌ Depende do DHCP do VirtualBox<br>❌ Pode ter conflitos |

**Recomendação**: Use **Bridge** para desenvolvimento Flutter - é mais simples e confiável.

---

## 🔍 Verificar Configuração de Rede

Para verificar se a rede está configurada corretamente:

```powershell
# Ver interfaces Host-Only
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list hostonlyifs

# Ver servidores DHCP
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list dhcpservers

# Ver VMs em execução
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list runningvms
```

---

## 🚀 Testar Device Funcionando

Quando o device iniciar com sucesso:

```powershell
cd C:\Users\Lucas\Desktop\aDiarista\mobile

# Verificar se Flutter detecta o device
flutter devices

# Deve mostrar algo como:
# Genymotion Pixel 6 (mobile) • 192.168.x.x:5555 • android-arm64 • Android 13
```

Se o device aparecer, execute:

```powershell
flutter run
```

---

## 🆘 Outros Problemas Comuns

### Device muito lento
**Solução**: 
1. Configure → RAM: aumente para 4096 MB
2. Configure → Processors: aumente para 2-4 CPUs
3. No Android: Settings → Developer Options → Window/Transition/Animator scale → 0.5x

### "flutter devices" não detecta Genymotion
**Solução**:
```powershell
# Conectar manualmente via ADB
cd C:\Users\Lucas\AppData\Local\Android\Sdk\platform-tools
.\adb.exe connect 192.168.56.101:5555
# (use o IP que aparece na barra de título do emulador)
```

### Google Play Store não disponível
**Solução**:
- No emulador rodando, arraste e solte o APK Open GApps
- Ou use a opção "Open GApps" no painel lateral do Genymotion
- Reinicie o device após instalação

---

## 📚 Links Úteis

- [Genymotion FAQ - DHCP](https://www.genymotion.com/faq/dhcp)
- [VirtualBox Network Settings](https://www.virtualbox.org/manual/ch06.html)
- [Flutter Android Setup](https://flutter.dev/docs/get-started/install/windows#android-setup)

---

**✅ Problema resolvido?** Execute `flutter run` e teste seu app aDiarista!
