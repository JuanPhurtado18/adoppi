import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/shelter.dart';
import '../domain/pet.dart';

class ShelterRepository {
  final SupabaseClient _client;

  ShelterRepository(this._client);

  Future<Shelter?> getCurrentShelter() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('shelters')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? Shelter.fromMap(response) : null;
  }

  Future<void> updateShelter({
    required String shelterId,
    required Map<String, dynamic> data,
  }) async {
    await _client
        .from('shelters')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', shelterId);
  }

  Future<void> updateShelterAvatar({
    required String userId,
    required String shelterId,
    required File file,
  }) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage.from('avatars').upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = _client.storage.from('avatars').getPublicUrl(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _client
        .from('shelters')
        .update({'avatar_url': '$url?v=$timestamp'})
        .eq('id', shelterId);
  }

  Future<List<Pet>> getShelterPets(String shelterId) async {
    final response = await _client
        .from('pets')
        .select('*, shelters(name, avatar_url, city)')
        .eq('shelter_id', shelterId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Pet.fromMap(e)).toList();
  }

  Future<void> createPet({
    required Pet pet,
    required String shelterId,
    required File photoFile,
  }) async {
    final fileName =
        '${shelterId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = 'pets/$fileName';

    await _client.storage.from('pets').upload(
      filePath,
      photoFile,
      fileOptions: const FileOptions(upsert: true),
    );

    final photoUrl =
        _client.storage.from('pets').getPublicUrl(filePath);

    final petData = pet.toMap(shelterId);
    petData['main_photo_url'] = photoUrl;

    await _client.from('pets').insert(petData);
  }

  Future<void> updatePet({
    required String petId,
    required Map<String, dynamic> data,
    File? newPhotoFile,
  }) async {
    if (newPhotoFile != null) {
      final fileName =
          '${petId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'pets/$fileName';

      await _client.storage.from('pets').upload(
        filePath,
        newPhotoFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final photoUrl =
          _client.storage.from('pets').getPublicUrl(filePath);
      data['main_photo_url'] = photoUrl;
    }

    await _client.from('pets').update(data).eq('id', petId);
  }

  Future<void> deletePet(String petId) async {
    await _client.from('pets').delete().eq('id', petId);
  }
}

final shelterRepositoryProvider = Provider<ShelterRepository>((ref) {
  return ShelterRepository(Supabase.instance.client);
});