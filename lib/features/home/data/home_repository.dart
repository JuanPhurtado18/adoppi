import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shelter_panel/domain/pet.dart';
import '../../shelter_panel/domain/shelter.dart';

class HomeRepository {
  final SupabaseClient _client;

  HomeRepository(this._client);

  // Obtener mascotas disponibles con filtros opcionales
  Future<List<Pet>> getPets({String? species, String? searchQuery}) async {
    var query = _client
        .from('pets')
        .select('*, shelters(name, avatar_url, city)')
        .eq('adoption_status', 'disponible');

    if (species != null && species != 'todos') {
      query = query.eq('species', species);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Pet.fromMap(e)).toList();
  }

  // Obtener refugios
  Future<List<Shelter>> getShelters({String? searchQuery}) async {
    var query = _client.from('shelters').select();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => Shelter.fromMap(e)).toList();
  }

  // Obtener perfil del adoptante
  Future<Map<String, dynamic>?> getAdoptantProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(Supabase.instance.client);
});
