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
      final profile = await _client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('DEBUG notification profile: $profile');

      final token = profile?['fcm_token'] as String?;
      if (token == null) {
        debugPrint('DEBUG notification: token is null for userId $userId');
        return;
      }

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
}
