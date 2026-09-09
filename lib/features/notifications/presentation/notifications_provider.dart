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
      .order('created_at', ascending: false)
      .limit(50);

  return (response as List).cast<Map<String, dynamic>>();
});

final unreadCountProvider = StreamProvider<int>((ref) async* {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    yield 0;
    return;
  }

  Future<int> getCount() async {
    final response = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  yield await getCount();

  await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
    final count = await getCount();

    yield count;
  }
});
