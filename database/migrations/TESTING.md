# 🧪 Guia de Testes - aDiarista

Este guia demonstra como estruturar e executar testes no Flutter.

## Tipos de Testes

### 1. Unit Tests
Testam funções e classes isoladamente.

```dart
// test/utils/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:adiarista/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('válida email correto', () {
      expect(isValidEmail('test@example.com'), isTrue);
    });

    test('rejeita email sem @', () {
      expect(isValidEmail('testexample.com'), isFalse);
    });

    test('rejeita email vazio', () {
      expect(isValidEmail(''), isFalse);
    });
  });

  group('Phone Validator', () {
    test('válida phone correto', () {
      expect(isValidPhone('11999999999'), isTrue);
    });

    test('rejeita phone curto', () {
      expect(isValidPhone('123'), isFalse);
    });
  });
}
```

### 2. Widget Tests
Testam widgets e UI components.

```dart
// test/widgets/loading_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adiarista/widgets/custom_widgets.dart';

void main() {
  testWidgets('LoadingButton renderiza corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test Button'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('LoadingButton mostra loading quando isLoading=true', 
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            label: 'Test',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### 3. Integration Tests
Testam fluxos completos do aplicativo.

```dart
// test_driver/app.dart
import 'package:adiarista/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fluxo de login completo', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Encontrar campos de entrada
    final emailField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).at(1);
    final loginButton = find.byType(ElevatedButton).first;

    // Preencher formulário
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    
    // Clicar botão
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verificar resultado
    expect(find.text('Home'), findsOneWidget);
  });
}
```

## Como Executar Testes

### Executar todos os testes
```bash
flutter test
```

### Executar teste específico
```bash
flutter test test/utils/validators_test.dart
```

### Executar com cobertura
```bash
flutter test --coverage
```

### Executar com detalhes
```bash
flutter test -v
```

## Estrutura de Diretórios de Testes

```
test/
├── models/              # Testes de modelos
│   ├── user_model_test.dart
│   ├── solicitacao_model_test.dart
│   └── ...
├── services/            # Testes de serviços
│   ├── auth_service_test.dart
│   ├── user_service_test.dart
│   └── ...
├── utils/               # Testes de utilitários
│   ├── validators_test.dart
│   └── ...
├── widgets/             # Testes de widgets
│   ├── custom_widgets_test.dart
│   └── ...
└── integration/         # Testes de integração
    ├── auth_flow_test.dart
    └── ...
```

## Exemplo Completo: Teste de Serviço

```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:adiarista/services/auth_service.dart';

// Mock do Supabase
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGotrueClient extends Mock implements GotrueClient {}

void main() {
  late AuthService authService;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    authService = AuthService();
  });

  group('AuthService', () {
    test('login com sucesso', () async {
      // Arrange
      when(mockClient.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => AuthResponse(
        user: User(id: '123', email: 'test@example.com'),
        session: Session(accessToken: 'token'),
      ));

      // Act
      final result = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result.user?.id, '123');
    });

    test('logout com sucesso', () async {
      when(mockClient.auth.signOut())
          .thenAnswer((_) async => null);

      await authService.logout();

      verify(mockClient.auth.signOut()).called(1);
    });
  });
}
```

## Boas Práticas

### ✅ Faça
- Teste comportamento, não implementação
- Use nomes descritivos para testes
- Siga o padrão AAA (Arrange, Act, Assert)
- Mantenha testes pequenos e focados
- Use mocks para dependências externas

### ❌ Evite
- Testes que dependem de outros testes
- Lógica complexa dentro de testes
- Testes que acessam APIs reais
- Testes não determinísticos
- Ignorar testes que falham

## Cobertura de Testes

### Meta Recomendada
- Models: 100% de cobertura
- Services: 80%+ de cobertura
- Widgets: 70%+ de cobertura
- Screens: 60%+ de cobertura

### Verificar Cobertura
```bash
# Gerar relatório de cobertura
flutter test --coverage

# Ver cobertura (Mac/Linux)
open coverage/lcov.html

# Ver cobertura (Windows)
start coverage/lcov.html
```

## CI/CD - Executar Testes Automaticamente

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
```

## Troubleshooting

### Problema: "Timeout" em testes
**Solução:**
```dart
test('meu teste', () async {
  // Aumentar timeout
  // timeout: Timeout(Duration(seconds: 10)),
}, timeout: Timeout(Duration(seconds: 30)));
```

### Problema: "Estado compartilhado entre testes"
**Solução:**
```dart
setUp(() {
  // Resetar estado antes de cada teste
});

tearDown(() {
  // Limpar após cada teste
});
```

### Problema: "Mock não funciona"
**Solução:**
```dart
// Verificar que o mock está sendo usado
verify(mockClient.method()).called(1);
```

## Próximos Passos

1. ✅ Entender tipos de testes
2. 📝 Escrever testes para suas features
3. 📊 Acompanhar cobertura
4. 🤖 Configurar CI/CD
5. 🔄 Executar testes antes de commit

## Recursos

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Testing Best Practices](https://flutter.dev/docs/testing/best-practices)

---

Última atualização: Janeiro 2024
