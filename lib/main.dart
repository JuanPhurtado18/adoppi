import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shelter_panel/presentation/controllers/shelter_controller.dart';
import 'features/home/presentation/screens/profile_tab.dart';
import 'features/chat/presentation/controllers/chat_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: AdoppiApp()));
}

class AdoppiApp extends ConsumerStatefulWidget {
  const AdoppiApp({super.key});

  @override
  ConsumerState<AdoppiApp> createState() => _AdoppiAppState();
}

class _AdoppiAppState extends ConsumerState<AdoppiApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        ref.invalidate(shelterControllerProvider);
        ref.invalidate(adoptantProfileProvider);
        ref.invalidate(adoptantConversationsProvider);
      }
      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        ref.invalidate(shelterControllerProvider);
        ref.invalidate(adoptantProfileProvider);
        ref.invalidate(adoptantConversationsProvider);
        ref.read(appRouterProvider).go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Adoppi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
