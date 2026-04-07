# ========================================================================
# Script de Setup Automático - aDiarista
# ========================================================================
# Este script configura todo o ambiente automaticamente
# Execute com: .\SETUP_AUTOMATICO.ps1
# ========================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  aDiarista - Setup Automático" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Função para verificar se um comando existe
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# ========================================================================
# 1. VERIFICAR FLUTTER
# ========================================================================
Write-Host "1. Verificando instalação do Flutter..." -ForegroundColor Yellow

if (Test-Command "flutter") {
    Write-Host "   ✅ Flutter encontrado!" -ForegroundColor Green
    flutter --version
} else {
    Write-Host "   ❌ Flutter NÃO encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   AÇÃO NECESSÁRIA:" -ForegroundColor Yellow
    Write-Host "   1. Baixe Flutter: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor White
    Write-Host "   2. Extraia em: C:\src\flutter" -ForegroundColor White
    Write-Host "   3. Adicione ao PATH: C:\src\flutter\bin" -ForegroundColor White
    Write-Host "   4. Reinicie o PowerShell" -ForegroundColor White
    Write-Host "   5. Execute este script novamente" -ForegroundColor White
    Write-Host ""
    
    $download = Read-Host "Deseja abrir a página de download? (s/n)"
    if ($download -eq "s") {
        Start-Process "https://docs.flutter.dev/get-started/install/windows"
    }
    
    exit 1
}

Write-Host ""

# ========================================================================
# 2. VERIFICAR DEPENDÊNCIAS DO FLUTTER
# ========================================================================
Write-Host "2. Verificando dependências do Flutter..." -ForegroundColor Yellow
flutter doctor

Write-Host ""
Write-Host "   ⚠️  Revise os avisos acima. Itens opcionais:" -ForegroundColor Yellow
Write-Host "   - Android Studio: Necessário para Android" -ForegroundColor White
Write-Host "   - Visual Studio: Necessário para Windows Desktop" -ForegroundColor White
Write-Host "   - Xcode: Apenas para macOS/iOS" -ForegroundColor White
Write-Host ""

# ========================================================================
# 3. NAVEGAR PARA PASTA MOBILE
# ========================================================================
Write-Host "3. Navegando para pasta mobile..." -ForegroundColor Yellow

$mobileDir = Join-Path $PSScriptRoot "mobile"

if (Test-Path $mobileDir) {
    Set-Location $mobileDir
    Write-Host "   ✅ Dentro de: $mobileDir" -ForegroundColor Green
} else {
    Write-Host "   ❌ Pasta mobile não encontrada!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ========================================================================
# 4. INSTALAR DEPENDÊNCIAS
# ========================================================================
Write-Host "4. Instalando dependências do Flutter..." -ForegroundColor Yellow
Write-Host "   (Isso pode levar alguns minutos...)" -ForegroundColor Gray

flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Dependências instaladas com sucesso!" -ForegroundColor Green
} else {
    Write-Host "   ❌ Erro ao instalar dependências!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ========================================================================
# 5. VERIFICAR CONFIGURAÇÃO DO SUPABASE
# ========================================================================
Write-Host "5. Verificando configuração do Supabase..." -ForegroundColor Yellow

$configFile = Join-Path $mobileDir "lib\config\supabase_config.dart"
$configContent = Get-Content $configFile -Raw

if ($configContent -match "tjenoowimxcsenuzpcyf") {
    Write-Host "   ✅ Supabase configurado corretamente!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Credenciais do Supabase não encontradas!" -ForegroundColor Yellow
    Write-Host "   Edite: lib/config/supabase_config.dart" -ForegroundColor White
}

Write-Host ""

# ========================================================================
# 6. LISTAR DISPOSITIVOS DISPONÍVEIS
# ========================================================================
Write-Host "6. Verificando dispositivos disponíveis..." -ForegroundColor Yellow

flutter devices

Write-Host ""

# ========================================================================
# 7. PERGUNTAR SE QUER RODAR
# ========================================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Concluído!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$run = Read-Host "Deseja iniciar o app agora? (s/n)"

if ($run -eq "s") {
    Write-Host ""
    Write-Host "Iniciando aDiarista em modo debug..." -ForegroundColor Yellow
    Write-Host "Aguarde o app abrir no dispositivo/emulador..." -ForegroundColor Gray
    Write-Host ""
    
    flutter run
} else {
    Write-Host ""
    Write-Host "Para rodar depois, execute:" -ForegroundColor Yellow
    Write-Host "  cd mobile" -ForegroundColor White
    Write-Host "  flutter run" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Pronto para desenvolver! 🚀" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
