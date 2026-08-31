import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PetCard({
    super.key,
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (pet.adoptionStatus) {
      case 'disponible':
        return AppColors.available;
      case 'en_proceso':
        return AppColors.inProcess;
      case 'adoptado':
        return AppColors.adopted;
      default:
        return AppColors.available;
    }
  }

  String _statusLabel() {
    switch (pet.adoptionStatus) {
      case 'disponible':
        return 'Disponible';
      case 'en_proceso':
        return 'En proceso';
      case 'adoptado':
        return 'Adoptado';
      default:
        return 'Disponible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Foto
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: pet.mainPhotoUrl != null
                ? Image.network(
                    pet.mainPhotoUrl!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor().withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species}${pet.breed != null ? ' · ${pet.breed}' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    petAgeLabel(pet.ageMonths),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Acciones
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.divider,
      child: const Icon(Icons.pets, color: AppColors.textHint, size: 32),
    );
  }
}