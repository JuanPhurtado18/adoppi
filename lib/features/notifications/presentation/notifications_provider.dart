import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final response = await Supabase.instance.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .eq('deleted_by_user', false)
      .order('created_at', ascending: false)
      .limit(50);

  return (response as List).cast<Map<String, dynamic>>();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 0;

  final response = await Supabase.instance.client
      .from('notifications')
      .select()
      .eq('user_id', userId)
      .eq('is_read', false)
      .eq('deleted_by_user', false);

  return (response as List).length;
});

final deletedNotificationIdsProvider = StateProvider<Set<String>>((ref) => {});
final locallyReadNotificationIdsProvider = StateProvider<Set<String>>(
  (ref) => {},
);
