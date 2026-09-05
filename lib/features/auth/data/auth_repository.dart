import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/geocoding_service.dart';

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
    });

    // Geolocalizar la dirección del refugio
    final fullAddress = '$address, $city, Colombia';
    final coordinates = await GeocodingService.getCoordinates(fullAddress);
    if (coordinates != null) {
      await _client
          .from('shelters')
          .update({
            'latitude': coordinates['latitude'],
            'longitude': coordinates['longitude'],
          })
          .eq('user_id', userId);
    }
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
