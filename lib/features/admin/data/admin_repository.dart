import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .neq('role', 'admin')
        .order('created_at', ascending: false);

    final users = (response as List).cast<Map<String, dynamic>>();

    // Para los refugios, obtener el avatar_url de la tabla shelters
    final result = await Future.wait(
      users.map((user) async {
        if (user['role'] == 'refugio') {
          final shelter = await _client
              .from('shelters')
              .select('avatar_url, name')
              .eq('user_id', user['id'])
              .maybeSingle();

          if (shelter != null) {
            return {
              ...user,
              'avatar_url': shelter['avatar_url'],
              'shelter_name': shelter['name'],
            };
          }
        }
        return user;
      }),
    );

    return result;
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) return null;

    if (profile['role'] == 'refugio') {
      final shelter = await _client
          .from('shelters')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return {
        ...profile,
        'avatar_url': shelter?['avatar_url'] ?? profile['avatar_url'],
        'shelter': shelter,
      };
    }

    return profile;
  }

  Future<void> blockUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_blocked': true})
        .eq('id', userId);
  }

  Future<void> unblockUser(String userId) async {
    await _client
        .from('profiles')
        .update({'is_blocked': false})
        .eq('id', userId);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final userDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      return ref.watch(adminRepositoryProvider).getUserDetails(userId);
    });
