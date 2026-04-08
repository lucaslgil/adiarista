import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

/// Tela de Login Minimalista - Apple Style
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Fazer login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();

      final tipoUsuario = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        switch (tipoUsuario) {
          case 'admin':
            context.go('/admin-home');
          case 'diarista':
            context.go('/worker-home');
          default:
            context.go('/client-home');
        }
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 48,
              vertical: 40,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Hero(
                        tag: 'app_logo',
                        child: Center(
                          child: Image.asset(
                            'assets/logo/aDiarista.png',
                            width: isSmallScreen ? 180 : 220,
                            height: isSmallScreen ? 180 : 220,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback se a logo não carregar
                              return Container(
                                width: isSmallScreen ? 180 : 220,
                                height: isSmallScreen ? 180 : 220,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Text(
                                    'aD',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Subtítulo
                      Text(
                        'Quem você precisa, quando você precisa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.colorSubtext,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 48 : 64),

                      // Mensagem de erro
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Formulário
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.4,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'seu@email.com',
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campo Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: Validators.password,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.4,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Esqueci senha
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implementar recuperação de senha
                                },
                                child: const Text('Esqueceu a senha?'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Botão Entrar
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Divisor
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'ou',
                                    style: TextStyle(
                                      color: AppTheme.colorSubtext,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botão Criar Conta
                            SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => context.push('/signup'),
                                child: const Text('Criar uma conta'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Texto rodapé
                      Text(
                        'Ao continuar, você concorda com nossos\nTermos de Uso e Política de Privacidade',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.colorSubtext,
                          height: 1.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widget Previews ────────────────────────────────────────────────────────

@Preview(name: 'Login Screen', brightness: Brightness.light)
Widget loginScreenPreview() => provider.Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );

@Preview(name: 'Login Screen - Dark', brightness: Brightness.dark)
Widget loginScreenDarkPreview() => provider.Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
