import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

/// Tela de Cadastro
class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  String _userType = 'cliente'; // 'cliente' ou 'diarista'
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Fazer cadastro
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'As senhas não correspondem';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      
      await authService.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
        tipoUsuario: _userType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado! Faça login para continuar.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Criar Conta',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escolha seu tipo de conta',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seleção de tipo de usuário
                    Row(
                      children: [
                        // Cliente
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _userType = 'cliente';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _userType == 'cliente'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 32,
                                    color: _userType == 'cliente'
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cliente',
                                    style: TextStyle(
                                      color: _userType == 'cliente'
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Diarista
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _userType = 'diarista';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _userType == 'diarista'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cleaning_services_outlined,
                                    size: 32,
                                    color: _userType == 'diarista'
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Diarista',
                                    style: TextStyle(
                                      color: _userType == 'diarista'
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Card do formulário
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome
                            Text(
                              'Nome Completo',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                hintText: 'Seu nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nome é obrigatório';
                                }
                                if (value.length < 3) {
                                  return 'Nome deve ter no mínimo 3 caracteres';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 16),

                            // Email
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'seu@email.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email é obrigatório';
                                }
                                if (!isValidEmail(value)) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 16),

                            // Senha
                            Text(
                              'Senha',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Senha é obrigatória';
                                }
                                if (value.length < 6) {
                                  return 'Senha deve ter no mínimo 6 caracteres';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 16),

                            // Confirmar Senha
                            Text(
                              'Confirmar Senha',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePasswordConfirm,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePasswordConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePasswordConfirm =
                                          !_obscurePasswordConfirm;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Confirme sua senha';
                                }
                                return null;
                              },
                              enabled: !_isLoading,
                            ),

                            const SizedBox(height: 24),

                            // Mensagem de erro
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (_errorMessage != null)
                              const SizedBox(height: 16),

                            // Botão de cadastro
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleSignup,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Cadastrar'),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Link para login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Já tem conta? ',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => context.go('/login'),
                                  child: Text(
                                    'Faça login',
                                    style: Theme.of(context)
                                        .textTheme.bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget Previews ────────────────────────────────────────────────────────

@Preview(name: 'Signup Screen')
Widget signupScreenPreview() => Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SignupScreen(),
      ),
    );
