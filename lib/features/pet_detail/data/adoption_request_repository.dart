import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdoptionRequestRepository {
  final SupabaseClient _client;

  AdoptionRequestRepository(this._client);

  // Obtener solicitud existente del adoptante para una mascota
  Future<Map<String, dynamic>?> getMyRequest({
    required String petId,
    required String adoptantId,
  }) async {
    final response = await _client
        .from('adoption_requests')
        .select()
        .eq('pet_id', petId)
        .eq('adoptant_id', adoptantId)
        .maybeSingle();

    return response;
  }

  // Crear solicitud de adopción
  Future<void> createRequest({
    required String petId,
    required String shelterId,
    required String adoptantId,
    String? message,
  }) async {
    await _client.from('adoption_requests').insert({
      'pet_id': petId,
      'shelter_id': shelterId,
      'adoptant_id': adoptantId,
      'status': 'pendiente',
      if (message != null) 'message': message,
    });

    // Cambiar estado de la mascota a en_proceso
    await _client
        .from('pets')
        .update({'adoption_status': 'en_proceso'})
        .eq('id', petId);
  }

  // Aprobar solicitud
  Future<void> approveRequest({
    required String requestId,
    required String petId,
  }) async {
    // Actualizar estado de la solicitud
    await _client
        .from('adoption_requests')
        .update({
          'status': 'aprobada',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);

    // Cambiar estado de la mascota a adoptado
    await _client
        .from('pets')
        .update({'adoption_status': 'adoptado'})
        .eq('id', petId);

    // Rechazar otras solicitudes pendientes de la misma mascota
    await _client
        .from('adoption_requests')
        .update({
          'status': 'rechazada',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('pet_id', petId)
        .neq('id', requestId)
        .eq('status', 'pendiente');
  }

  // Rechazar solicitud
  Future<void> rejectRequest({
    required String requestId,
    required String petId,
  }) async {
    await _client
        .from('adoption_requests')
        .update({
          'status': 'rechazada',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);

    // Verificar si hay otras solicitudes pendientes
    final pending = await _client
        .from('adoption_requests')
        .select()
        .eq('pet_id', petId)
        .eq('status', 'pendiente');

    // Si no hay más solicitudes pendientes, volver a disponible
    if ((pending as List).isEmpty) {
      await _client
          .from('pets')
          .update({'adoption_status': 'disponible'})
          .eq('id', petId);
    }
  }

  // Obtener solicitudes del refugio con info del adoptante y mascota
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
}

final adoptionRequestRepositoryProvider = Provider<AdoptionRequestRepository>((
  ref,
) {
  return AdoptionRequestRepository(Supabase.instance.client);
});

// Provider para verificar si el adoptante ya tiene solicitud
final myRequestProvider =
    FutureProvider.family<Map<String, dynamic>?, (String, String)>((
      ref,
      params,
    ) async {
      final petId = params.$1;
      final adoptantId = params.$2;
      return ref
          .watch(adoptionRequestRepositoryProvider)
          .getMyRequest(petId: petId, adoptantId: adoptantId);
    });
