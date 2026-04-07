# 🤝 Guia de Contribuição - aDiarista

Obrigado por querer contribuir com o aDiarista! Este documento explica como fazer isso de forma organizada.

## 📋 Antes de Começar

1. Leia o [README.md](README.md)
2. Entenda a [ARCHITECTURE.md](ARCHITECTURE.md)
3. Consulte o [CHECKLIST.md](CHECKLIST.md) para saber o que precisa ser feito
4. Fork o repositório

## 🔧 Setup de Desenvolvimento

```bash
# Clone seu fork
git clone https://github.com/seu-usuario/adiarista.git
cd adiarista/mobile

# Configure Supabase (veja SETUP.md)
# Edite lib/config/supabase_config.dart

# Installe dependências
flutter pub get

# Rode localmente
flutter run
```

## 📝 Processo de Contribuição

### 1. Criar Branch
```bash
git checkout -b feature/descricao-da-feature
# ou
git checkout -b fix/descricao-do-bug
```

**Convenção de nomes:**
- `feature/criar-solicitacao` - Nova funcionalidade
- `fix/validacao-email` - Correção de bug
- `docs/adicionar-tutorial` - Documentação
- `test/testes-auth` - Testes
- `refactor/melhorar-estrutura` - Refatoração

### 2. Código

#### Padrão de Código
```dart
// ✅ BOM
class AuthService {
  /// Fazer login com email e senha
  /// 
  /// [email] Email do usuário
  /// [password] Senha (mínimo 6 caracteres)
  /// 
  /// Lança [AuthException] se falhar
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Implementação
  }
}

// ❌ EVITAR
class auth {
  // Sem documentação, nomes pequenos, etc
}
```

#### Checklist de Código
- [ ] Seguir Dart style guide
- [ ] Adicionar comentários em partes complexas
- [ ] Documentar funções públicas
- [ ] Sem warnings do analyzer (`flutter analyze`)
- [ ] Nomes descritivos
- [ ] Tratamento de erros
- [ ] Null safety aplicado

#### Formato de Código
```bash
# Formatar automaticamente
dart format lib/

# Analisar código
flutter analyze

# Se houver problemas
# Corriga manualmente antes de fazer commit
```

### 3. Testes

**Todo código deve ter testes!**

```dart
// test/models/user_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:adiarista/models/user.dart';

void main() {
  test('User.fromJson cria usuário corretamente', () {
    final json = {
      'id': '123',
      'nome': 'João',
      'email': 'joao@example.com',
      'tipo_usuario': 'cliente',
      'criado_em': '2024-01-10T10:00:00Z',
    };

    final user = User.fromJson(json);
    
    expect(user.id, '123');
    expect(user.nome, 'João');
  });
}
```

**Rodar testes:**
```bash
# Todos
flutter test

# Arquivo específico
flutter test test/models/user_model_test.dart

# Com cobertura
flutter test --coverage
```

### 4. Commit

```bash
# Commits pequenos e focados
git add .
git commit -m "feat: criar função de login"

# Mensagens claras
# feat: nova feature
# fix: correção de bug
# docs: documentação
# test: testes
# refactor: refatoração
# style: formatação
```

#### Exemplo de Bom Commit
```
feat: adicionar validação de email

- Adicionar função isValidEmail() em validators.dart
- Adicionar testes para validação
- Atualizar LoginScreen para usar validação
- Adicionar documentação com exemplos

Fecha #123
```

### 5. Push e Pull Request

```bash
# Push para seu fork
git push origin feature/sua-feature

# Abrir PR no GitHub
# Preencha o template com:
# - Descrição das mudanças
# - Por que fez estas mudanças
# - Como testar
# - Screenshots (se UI)
# - Closes #num (se fecha issue)
```

#### Template de PR
```markdown
## Descrição
Adiciona funcionalidade de validação de email.

## Tipo de Mudança
- [ ] New feature
- [x] Bug fix
- [ ] Breaking change

## Como Testar
1. Abrir LoginScreen
2. Tentar login com email inválido
3. Deve mostrar erro

## Screenshots
[Se aplicável]

## Checklist
- [x] Código formatado
- [x] Testes adicionados
- [x] Sem warnings
- [x] Documentado
```

### 6. Code Review

- [ ] Aguarde feedback
- [ ] Responda todos os comentários
- [ ] Faça ajustes se necessário
- [ ] Converse com o reviewer
- [ ] Mantenha a educação

## 📋 Guia de Estilo

### Nomenclatura
```dart
// Classes: PascalCase
class LoginScreen { }

// Funções/Variáveis: camelCase
void handleLogin() { }
String userName = 'João';

// Constantes: CONSTANT_CASE ou camelCase
static const API_URL = 'https://...';
static const appVersion = '1.0.0';

// Arquivos: snake_case
login_screen.dart
auth_service.dart
user_profile.dart
```

### Estrutura de Arquivos
```dart
// 1. Imports
import 'package:flutter/material.dart';
import '../../config/theme.dart';

// 2. Classe
class MyClass {
  // 3. Constantes
  static const String title = 'Title';
  
  // 4. Variáveis
  final String name;
  bool _isLoading = false;
  
  // 5. Construtor
  MyClass({required this.name});
  
  // 6. Métodos (@override primeiro)
  @override
  void initState() { }
  
  // 7. Build ou métodos pubcos
  Widget build(BuildContext context) { }
  
  // 8. Métodos privados
  void _handleAction() { }
}
```

### Comentários
```dart
// ✅ BOM
/// Calcula a média de avaliações
/// 
/// Returns o valor médio entre 0 e 5
double calculateAverage(List<int> ratings) {
  return ratings.isEmpty ? 0 : ratings.fold(0, (a, b) => a + b) / ratings.length;
}

// ❌ EVITAR
// calcula média (óbvio pelo nome)
double avg(List<int> r) {
  // código
}
```

## 🧹 Limpeza Antes de Submeter

```bash
# 1. Formatar
dart format lib/

# 2. Analisar
flutter analyze

# 3. Testar
flutter test

# 4. Build (verificar se compila)
flutter build apk --release  # ou ios

# 5. Verificar diferenças
git diff

# 6. Limpar não-necessário
git status
```

## 🐛 Reportando Bugs

Abra uma Issue com:

```markdown
## Descrição
Descreva o bug claramente.

## Steps para Reproduzir
1. Abrir app
2. Ir para ...
3. Clicar em ...
4. Ver erro

## Comportamento Esperado
O que deveria acontecer

## Comportamento Atual
O que está acontecendo

## Ambiente
- Versão Flutter: 
- Device: Android/iOS
- Versão do app: 

## Screenshots/Logs
Adicione se disponível
```

## 💡 Sugerindo Melhorias

Abra uma Issue com:

```markdown
## Sugestão
Descrição clara da melhoria

## Benefício
Por que seria útil

## Implementação Proposta
Como você propõe implementar (se aplicável)

## Alternativas Consideradas
Outras abordagens
```

## 📚 Padrões de Projeto Usados

### Service Locator Pattern
```dart
// ✅ Usar Provider
final authService = context.read<AuthService>();

// Não:
// AuthService().login() // cria nova instância
```

### Validação de Input
```dart
// ✅ Sempre validar
if (email.isEmpty || !email.contains('@')) {
  showError('Email inválido');
  return;
}
```

### Error Handling
```dart
// ✅ Sempre um try-catch
try {
  await authService.login(email, password);
} on AuthException catch (e) {
  showError(e.message);
} catch (e) {
  showError('Erro inesperado');
}
```

### Modelo/Serialização
```dart
// ✅ Sempre ter fromJson e toJson
class User {
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
  };
}
```

## 🚀 Tipos de Contribuição

### Code Contributions
- Novas features
- Bug fixes
- Performance improvements
- Refactoring

### Documentation
- README melhorado
- Novos guias
- Exemplos de código
- Tradução

### Testing
- Unit tests
- Integration tests
- Test coverage

### Comunidade
- Reportar bugs
- Sugerir features
- Code reviews
- Mentoring

## 🏆 Boas Práticas

### ✅ Faça
- Commits pequenos e atômicos
- Testes antes de PR
- Rebase antes de merge
- Comentários construtivos
- Mantenha branches atualizadas
- Discuta antes de mudanças grandes

### ❌ Evite
- Commits hugados
- PR sem testes
- Código sem documentação
- Conflitos não resolvidos
- Código duplicado
- Ignorar feedback

## 📞 Comunicação

**Dúvidas?**
- Abra uma issue
- Comente no PR
- Comunidade Discord (futur0)
- Email: dev@adiarista.com.br

**Linguagem:**
- Português ou Inglês
- Respectoso e profissional
- Foco na ideia, não na pessoa

## 🎓 Aprender com o Projeto

**Conceitos cobertos:**
- Flutter & Dart
- State management (Provider)
- Backend com Supabase
- PostgreSQL/SQL
- Autenticação e segurança
- Testes
- CI/CD

**Recursos:**
- Flutter docs: https://flutter.dev
- Dart docs: https://dart.dev
- Supabase docs: https://supabase.com/docs

## 📜 Licença

Ao contribuir, você concorda que seu código será licenciado sob a mesma licença do projeto (MIT).

## 🎉 Agradecimentos

Valorizamos muito sua contribuição! Todo commit conta.

---

**Última atualização:** Janeiro 2024

Obrigado por contribuir! 🙏

