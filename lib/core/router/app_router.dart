import 'package:adoppi/features/admin/presentation/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/shelter_panel/presentation/screens/shelter_panel_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';

final passwordRecoveryModeProvider = StateProvider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final isAuthenticated = session != null;
      final isRecoveryMode = ref.read(passwordRecoveryModeProvider);

      // Permitir recuperación de contraseña
      if (isRecoveryMode && state.matchedLocation == AppRoutes.newPassword) {
        return null;
      }

      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.verifyOtp ||
          state.matchedLocation == AppRoutes.newPassword;

      // No hay sesión → solo puede estar en rutas públicas
      if (!isAuthenticated) {
        if (isAuthRoute || state.matchedLocation == AppRoutes.splash) {
          return null;
        }

        return AppRoutes.login;
      }

      // Hay sesión y está intentando entrar a login/register/etc.
      if (isAuthenticated && isAuthRoute && !isRecoveryMode) {
        final userId = session.user.id;

        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role =
            profile?['role'] as String? ??
            session.user.userMetadata?['role'] as String?;

        if (role == 'admin') {
          return AppRoutes.adminPanel;
        }

        if (role == 'refugio') {
          return AppRoutes.shelterPanel;
        }

        return AppRoutes.home;
      }

      // Hay sesión y está en splash → determinar destino por el perfil
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        final userId = session.user.id;

        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role =
            profile?['role'] as String? ??
            session.user.userMetadata?['role'] as String?;

        if (role == 'admin') {
          return AppRoutes.adminPanel;
        }

        if (role == 'refugio') {
          return AppRoutes.shelterPanel;
        }

        return AppRoutes.home;
      }

      // Si está en home pero realmente es admin/refugio,
      // llevarlo a su panel correspondiente.
      if (isAuthenticated && state.matchedLocation == AppRoutes.home) {
        final userId = session.user.id;

        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role =
            profile?['role'] as String? ?? session.user.userMetadata?['role'];

        if (role == 'admin') {
          return AppRoutes.adminPanel;
        }

        if (role == 'refugio') {
          return AppRoutes.shelterPanel;
        }
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
        builder: (context, state) => const PlaceholderScreen(title: 'Registro'),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) =>
            VerifyOtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.newPassword,
        name: 'newPassword',
        builder: (context, state) => const NewPasswordScreen(),
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
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.shelterPanel,
        name: 'shelterPanel',
        builder: (context, state) => const ShelterPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        name: 'adminPanel',
        builder: (context, state) => const AdminScreen(),
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
        builder: (context, state) => const PlaceholderScreen(title: 'Refugios'),
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
        builder: (context, state) => const PlaceholderScreen(title: 'Perfil'),
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
  static const String terms = '/terms';
  static const String home = '/home';
  static const String shelterPanel = '/shelter-panel';
  static const String adminPanel = '/admin-panel';
  static const String petDetail = '/pets/:id';
  static const String shelters = '/shelters';
  static const String shelterDetail = '/shelters/:id';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String newPassword = '/new-password';
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
