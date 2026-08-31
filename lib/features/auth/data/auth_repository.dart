import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

Future<void> signUpAdoptant({
  required String email,
  required String password,
  required String fullName,
  required File avatarFile,
}) async {
  try {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
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

  } catch (e) {
    print('ERROR DETALLADO: $e');
    rethrow;
  }
}

  Future<void> signUpShelter({
    required String email,
    required String password,
    required String shelterName,
    required String address,
    required File avatarFile,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': shelterName,
        'role': 'refugio',
      },
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
      'avatar_url': avatarUrl,
      'email':email,
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

    await _client.storage.from(bucket).upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _client.storage.from(bucket).getPublicUrl(filePath);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});