import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/auth_callback_screen.dart';
import '../screens/client/home_client_screen.dart';
import '../screens/client/buscar_diaristas_screen.dart';
import '../screens/client/nova_solicitacao_screen.dart';
import '../screens/worker/home_worker_screen.dart';
import '../screens/admin/admin_home_screen.dart';

/// Configuração de roteamento do aplicativo
class AppRouter {
  static final GoRouter router = GoRouter(
    // Captura rotas desconhecidas (ex: callback de email do Supabase)
    errorBuilder: (context, state) => const AuthCallbackScreen(),
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/client-home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/client-home',
        builder: (context, state) => const HomeClientScreen(),
      ),
      GoRoute(
        path: '/worker-home',
        builder: (context, state) => const HomeWorkerScreen(),
      ),
      GoRoute(
        path: '/admin-home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/buscar-diaristas',
        builder: (context, state) => const BuscarDiaristasScreen(),
      ),
      GoRoute(
        path: '/nova-solicitacao',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NovaSolicitacaoScreen(
            tipoInicial: extra?['tipo'] as String?,
            diaristIdInicial: extra?['diaristId'] as String?,
          );
        },
      ),
    ],
  );
}
