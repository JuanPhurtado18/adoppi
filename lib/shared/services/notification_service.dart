import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener token FCM del usuario
      final profile = await _client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .maybeSingle();

      final token = profile?['fcm_token'] as String?;
      if (token == null) return;

      // Llamar a la Edge Function
      await _client.functions.invoke(
        'send-notification',
        body: {
          'token': token,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      // Guardar notificación en la base de datos
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'nuevo_mensaje',
        'reference_id': data?['reference_id'],
      });
    } catch (e) {
      // Silencioso si falla
    }
  }
}
