import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (!isAuthenticated && !isAuthRoute) {
        if (state.matchedLocation != AppRoutes.splash) {
          return AppRoutes.login;
        }
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Registro'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Recuperar contraseña'),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: 'terms',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Términos y condiciones'),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeTemp(),
      ),
      GoRoute(
        path: AppRoutes.petDetail,
        name: 'petDetail',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PlaceholderScreen(title: 'Mascota $petId');
        },
      ),
      GoRoute(
        path: AppRoutes.shelters,
        name: 'shelters',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Refugios'),
      ),
      GoRoute(
        path: AppRoutes.shelterDetail,
        name: 'shelterDetail',
        builder: (context, state) {
          final shelterId = state.pathParameters['id']!;
          return PlaceholderScreen(title: 'Refugio $shelterId');
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) => const PlaceholderScreen(title: 'Chat'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Notificaciones'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Perfil'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Configuración'),
      ),
    ],
  );
});

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String terms = '/terms';
  static const String home = '/home';
  static const String petDetail = '/pets/:id';
  static const String shelters = '/shelters';
  static const String shelterDetail = '/shelters/:id';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class HomeTemp extends ConsumerWidget {
  const HomeTemp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ),
    );
  }
}