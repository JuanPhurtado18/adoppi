import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Verificar si el usuario tiene notificaciones habilitadas
      // Buscar primero en profiles (adoptante)
      final profile = await _client
          .from('profiles')
          .select('fcm_token, notifications_enabled')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('DEBUG notification profile: $profile');

      // Si tiene notificaciones desactivadas en profiles, no enviar
      if (profile != null && profile['notifications_enabled'] == false) {
        debugPrint(
          'DEBUG notification: notificaciones desactivadas para userId $userId',
        );
        return;
      }

      // Si no está en profiles, buscar en shelters (refugio)
      if (profile == null) {
        final shelter = await _client
            .from('shelters')
            .select('notifications_enabled')
            .eq('user_id', userId)
            .maybeSingle();

        if (shelter != null && shelter['notifications_enabled'] == false) {
          debugPrint(
            'DEBUG notification: notificaciones desactivadas para refugio userId $userId',
          );
          return;
        }
      }

      final token = profile?['fcm_token'] as String?;
      if (token == null) {
        debugPrint('DEBUG notification: token is null for userId $userId');
        // Igual insertamos la notificación en la tabla aunque no haya token push
      } else {
        final result = await _client.functions.invoke(
          'send-notification',
          body: {
            'token': token,
            'title': title,
            'body': body,
            'data': data ?? {},
          },
        );
        debugPrint('DEBUG notification function result: ${result.data}');
      }

      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'nuevo_mensaje',
        'reference_id': data?['reference_id'],
      });

      debugPrint('DEBUG notification inserted successfully');
    } catch (e) {
      debugPrint('DEBUG notification error: $e');
    }
  }

  // Actualizar preferencia de notificaciones para adoptante
  static Future<void> updateAdoptantNotificationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    await _client
        .from('profiles')
        .update({'notifications_enabled': enabled})
        .eq('id', userId);
  }

  // Actualizar preferencia de notificaciones para refugio
  static Future<void> updateShelterNotificationsEnabled({
    required String userId,
    required bool enabled,
  }) async {
    await _client
        .from('shelters')
        .update({'notifications_enabled': enabled})
        .eq('user_id', userId);
  }
}
