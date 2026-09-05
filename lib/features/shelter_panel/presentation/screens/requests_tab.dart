import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/pet_detail/data/adoption_request_repository.dart';

final shelterRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      shelterId,
    ) async {
      final repo = ref.watch(adoptionRequestRepositoryProvider);
      return repo.getShelterRequests(shelterId);
    });

class RequestsTab extends ConsumerWidget {
  final String shelterId;
  const RequestsTab({super.key, required this.shelterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(shelterRequestsProvider(shelterId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar solicitudes',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        data: (requests) => requests.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tienes solicitudes aún',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(shelterRequestsProvider(shelterId));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _RequestCard(
                      request: request,
                      onApprove: () async {
                        await ref
                            .read(adoptionRequestRepositoryProvider)
                            .approveRequest(
                              requestId: request['id'],
                              petId: request['pet_id'],
                            );
                        ref.invalidate(shelterRequestsProvider(shelterId));
                      },
                      onReject: () async {
                        await ref
                            .read(adoptionRequestRepositoryProvider)
                            .rejectRequest(
                              requestId: request['id'],
                              petId: request['pet_id'],
                            );
                        ref.invalidate(shelterRequestsProvider(shelterId));
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final pet = request['pets'] as Map<String, dynamic>? ?? {};
    final adoptant = request['profiles'] as Map<String, dynamic>? ?? {};
    final status = request['status'] as String? ?? 'pendiente';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'aprobada':
        statusColor = AppColors.available;
        statusLabel = 'Aprobada';
        break;
      case 'rechazada':
        statusColor = AppColors.error;
        statusLabel = 'Rechazada';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Pendiente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar adoptante
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.divider,
                backgroundImage: adoptant['avatar_url'] != null
                    ? NetworkImage(adoptant['avatar_url'])
                    : null,
                child: adoptant['avatar_url'] == null
                    ? const Icon(Icons.person, color: AppColors.textHint)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adoptant['full_name'] ?? 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Interesado en ${pet['name'] ?? 'mascota'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Foto de la mascota
          if (pet['main_photo_url'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: pet['main_photo_url'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.divider,
                      child: const Icon(Icons.pets, color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      pet['species'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Mensaje del adoptante
          if (request['message'] != null &&
              (request['message'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              '"${request['message']}"',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Botones de acción
          if (status == 'pendiente') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmAction(
                      context: context,
                      title: 'Rechazar solicitud',
                      message:
                          '¿Estás seguro que quieres rechazar esta solicitud?',
                      onConfirm: onReject,
                      confirmLabel: 'Rechazar',
                      isDestructive: true,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmAction(
                      context: context,
                      title: 'Aprobar solicitud',
                      message:
                          '¿Estás seguro que quieres aprobar esta solicitud? La mascota pasará a estado "Adoptado".',
                      onConfirm: onApprove,
                      confirmLabel: 'Aprobar',
                      isDestructive: false,
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmLabel,
    required bool isDestructive,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
