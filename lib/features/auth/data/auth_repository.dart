import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      debugPrint('👤 [AUTH] userId: $userId');
      debugPrint('👤 [AUTH] metadata: ${response.user?.userMetadata}');

      if (userId != null) {
        final profile = await _client
            .from('profiles')
            .select('is_blocked, role')
            .eq('id', userId)
            .maybeSingle();

        // Si no hay perfil (admin creado manualmente) o no está bloqueado, continuar
        if (profile?['is_blocked'] == true) {
          await _client.auth.signOut();
          throw Exception('blocked');
        }
      }

      return response;
    } catch (e) {
      debugPrint('❌ [AUTH] Error: $e');
      rethrow;
    }
  }

  Future<void> signUpAdoptant({
    required String email,
    required String password,
    required String fullName,
    required String lastName,
    required int age,
    required String phone,
    required String city,
    required File avatarFile,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'last_name': lastName,
        'age': age,
        'phone': phone,
        'city': city,
        'role': 'adoptante',
      },
    );

    final userId = response.user?.id;
    if (userId == null) throw Exception('Error al crear el usuario');

    final avatarUrl = await _uploadAvatar(
      userId: userId,
      file: avatarFile,
      bucket: 'avatars',
    );

    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

  Future<void> signUpShelter({
    required String email,
    required String password,
    required String shelterName,
    required String address,
    required String city,
    required String phone,
    required String description,
    required String schedule,
    required File avatarFile,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': shelterName, 'role': 'refugio'},
    );

    final userId = response.user?.id;
    if (userId == null) throw Exception('Error al crear el usuario');

    final avatarUrl = await _uploadAvatar(
      userId: userId,
      file: avatarFile,
      bucket: 'avatars',
    );

    await _client.from('shelters').insert({
      'user_id': userId,
      'name': shelterName,
      'address': address,
      'city': city,
      'phone': phone,
      'description': description,
      'schedule': schedule,
      'email': email,
      'avatar_url': avatarUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String> _uploadAvatar({
    required String userId,
    required File file,
    required String bucket,
  }) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from(bucket)
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from(bucket).getPublicUrl(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$url?v=$timestamp';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
