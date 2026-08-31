import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/shelter.dart';
import '../domain/pet.dart';

class ShelterRepository {
  final SupabaseClient _client;

  ShelterRepository(this._client);

  // Obtener refugio del usuario actual
  Future<Shelter?> getCurrentShelter() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('shelters')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Shelter.fromMap(response);
  }

  // Actualizar información del refugio
  Future<void> updateShelter({
    required String shelterId,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('shelters').update(data).eq('id', shelterId);
  }

  // Actualizar foto del refugio
  Future<String> updateShelterAvatar({
    required String userId,
    required String shelterId,
    required File file,
  }) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('avatars').getPublicUrl(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final urlWithVersion = '$url?v=$timestamp';

    await _client
        .from('shelters')
        .update({'avatar_url': urlWithVersion})
        .eq('id', shelterId);

    return urlWithVersion;
  }

  // Obtener mascotas del refugio
  Future<List<Pet>> getShelterPets(String shelterId) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('shelter_id', shelterId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Pet.fromMap(e)).toList();
  }

  // Publicar mascota
  Future<void> createPet({
    required Pet pet,
    required String shelterId,
    required File photoFile,
  }) async {
    final response = await _client
        .from('pets')
        .insert(pet.toMap(shelterId))
        .select()
        .single();

    final petId = response['id'] as String;

    final photoUrl = await _uploadPetPhoto(petId: petId, file: photoFile);

    await _client
        .from('pets')
        .update({'main_photo_url': photoUrl})
        .eq('id', petId);
  }

  // Editar mascota
  Future<void> updatePet({
    required String petId,
    required Map<String, dynamic> data,
    File? newPhotoFile,
  }) async {
    if (newPhotoFile != null) {
      final photoUrl = await _uploadPetPhoto(petId: petId, file: newPhotoFile);
      data['main_photo_url'] = photoUrl;
    }

    await _client.from('pets').update(data).eq('id', petId);
  }

  // Eliminar mascota
  Future<void> deletePet(String petId) async {
    await _client.from('pets').delete().eq('id', petId);
  }

  // Obtener solicitudes del refugio
  Future<List<Map<String, dynamic>>> getShelterRequests(
    String shelterId,
  ) async {
    final response = await _client
        .from('adoption_requests')
        .select('''
          *,
          pets(name, main_photo_url, species),
          profiles(full_name, avatar_url)
        ''')
        .eq('shelter_id', shelterId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Actualizar estado de solicitud
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _client
        .from('adoption_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  // Subir foto de mascota
  Future<String> _uploadPetPhoto({
    required String petId,
    required File file,
  }) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$petId/main.$fileExt';

    await _client.storage
        .from('pets')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('pets').getPublicUrl(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$url?v=$timestamp';
  }
}

final shelterRepositoryProvider = Provider<ShelterRepository>((ref) {
  return ShelterRepository(Supabase.instance.client);
});
