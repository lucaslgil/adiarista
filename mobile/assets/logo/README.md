# 🎨 Pasta de Logomarcas - aDiarista

## 📁 Estrutura Recomendada

Coloque suas logomarcas nesta pasta seguindo as convenções:

### Variações de Logo:
- `logo.png` - Logo principal (fundo transparente, 512x512px ou maior)
- `logo_white.png` - Logo em branco (para fundos escuros)
- `logo_dark.png` - Logo escura (para fundos claros)
- `logo_icon.png` - Apenas ícone sem texto (256x256px)
- `logo_horizontal.png` - Logo horizontal com nome (uso em headers)
- `logo_splash.png` - Logo para splash screen (1024x1024px)

### Formatos Aceitos:
- **PNG** (recomendado) - com transparência
- **SVG** (ideal) - escalável para qualquer tamanho
- **WEBP** - para web, menor tamanho

### Tamanhos Recomendados:
| Uso | Tamanho Mínimo | Recomendado |
|-----|---------------|-------------|
| App Icon | 1024x1024px | 1024x1024px |
| Logo Principal | 512x512px | 1024x1024px |
| Header/AppBar | 120x40px | 240x80px |
| Splash Screen | 512x512px | 2048x2048px |

## 🎯 Dicas:

1. **Use fundo transparente** (PNG com alpha channel)
2. **Mantenha proporção** (quadrado para ícones)
3. **Cores consistentes** com o tema do app
4. **Versão simplificada** para tamanhos pequenos

## 📝 Depois de adicionar a logo:

Atualize o `pubspec.yaml` se necessário:
```yaml
flutter:
  assets:
    - assets/logo/
```

## 🚀 Uso no Código:

```dart
// Logo principal
Image.asset('assets/logo/logo.png', width: 200)

// Logo para tema escuro
Image.asset('assets/logo/logo_white.png')

// Ícone pequeno
Image.asset('assets/logo/logo_icon.png', width: 48)
```
