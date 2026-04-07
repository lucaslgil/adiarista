import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/client/home_client_screen.dart';
import '../screens/worker/home_worker_screen.dart';

/// Configuração de roteamento do aplicativo
class AppRouter {
  static final GoRouter router = GoRouter(
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        // Redirecionar para home apropriada baseado no tipo de usuário
        // Por enquanto, redireciona para cliente
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
        path: '/client-home',
        builder: (context, state) => const HomeClientScreen(),
      ),
      GoRoute(
        path: '/worker-home',
        builder: (context, state) => const HomeWorkerScreen(),
      ),
    ],
  );
}
