import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shelter_panel/domain/pet.dart';
import '../../shelter_panel/domain/shelter.dart';

class PetDetailRepository {
  final SupabaseClient _client;

  PetDetailRepository(this._client);

  Future<Pet> getPetById(String petId) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('id', petId)
        .single();

    return Pet.fromMap(response);
  }

  Future<Shelter> getShelterById(String shelterId) async {
    final response = await _client
        .from('shelters')
        .select()
        .eq('id', shelterId)
        .single();

    return Shelter.fromMap(response);
  }

  Future<List<Pet>> getShelterPets(String shelterId) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('shelter_id', shelterId)
        .eq('adoption_status', 'disponible')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Pet.fromMap(e)).toList();
  }
}

final petDetailRepositoryProvider = Provider<PetDetailRepository>((ref) {
  return PetDetailRepository(Supabase.instance.client);
});

final petByIdProvider = FutureProvider.family<Pet, String>((ref, petId) async {
  return ref.watch(petDetailRepositoryProvider).getPetById(petId);
});

final shelterByIdProvider = FutureProvider.family<Shelter, String>((
  ref,
  shelterId,
) async {
  return ref.watch(petDetailRepositoryProvider).getShelterById(shelterId);
});

final shelterPetsProvider = FutureProvider.family<List<Pet>, String>((
  ref,
  shelterId,
) async {
  return ref.watch(petDetailRepositoryProvider).getShelterPets(shelterId);
});
