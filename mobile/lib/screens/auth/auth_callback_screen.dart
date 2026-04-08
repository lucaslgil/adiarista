import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

/// Tela intermediaria que processa o callback de autenticacao do Supabase
/// (confirmacao de email, redefinicao de senha, etc.)
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({Key? key}) : super(key: key);

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String _mensagem = 'Confirmando seu email...';

  @override
  void initState() {
    super.initState();
    _processCallback();
  }

  Future<void> _processCallback() async {
    // Aguarda o supabase_flutter processar o token da URL automaticamente
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = context.read<AuthService>();

    if (authService.isAuthenticated) {
      final tipo = await authService.getCurrentUserType();
      if (!mounted) return;
      switch (tipo) {
        case 'admin':
          context.go('/admin-home');
        case 'diarista':
          context.go('/worker-home');
        default:
          context.go('/client-home');
      }
    } else {
      setState(() {
        _mensagem = 'Redirecionando para o login...';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              _mensagem,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.colorSubtext,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}