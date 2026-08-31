import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final void Function(String status) onUpdateStatus;

  const RequestCard({
    super.key,
    required this.request,
    required this.onUpdateStatus,
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
                radius: 20,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          if (request['message'] != null &&
              (request['message'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              request['message'],
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (status == 'pendiente') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onUpdateStatus('rechazada'),
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
                    onPressed: () => onUpdateStatus('aprobada'),
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
}