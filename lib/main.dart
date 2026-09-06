import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/shelter_panel/presentation/controllers/shelter_controller.dart';
import 'features/home/presentation/screens/profile_tab.dart';
import 'features/chat/presentation/controllers/chat_controller.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    _setupAuthListener();
    _setupFCM();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        ref.invalidate(shelterControllerProvider);
        ref.invalidate(adoptantProfileProvider);
        ref.invalidate(adoptantConversationsProvider);
        _saveFCMToken();
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

  Future<void> _setupFCM() async {
    // Solicitar permisos
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Guardar token cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'Adoppi',
          body: notification.body ?? '',
        );
      }
    });

    // Guardar token FCM
    await _saveFCMToken();
  }

  Future<void> _saveFCMToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
      }
    } catch (e) {
      // Silencioso si falla
    }
  }

  void _showLocalNotification({required String title, required String body}) {
    // Por ahora solo imprimimos, luego agregamos flutter_local_notifications
    debugPrint('Notificación: $title - $body');
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
