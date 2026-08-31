import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/pet_controller.dart';
import '../widgets/pet_card.dart';
import '../widgets/pet_form.dart';
import '../../domain/pet.dart';

class PetsTab extends ConsumerWidget {
  final String shelterId;
  const PetsTab({super.key, required this.shelterId});

  void _openPetForm(BuildContext context, WidgetRef ref, {Pet? pet}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _PetFormModal(
        shelterId: shelterId,
        pet: pet,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
            '¿Estás seguro que quieres eliminar a ${pet.name}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(petControllerProvider(shelterId).notifier)
                  .deletePet(pet.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mascota eliminada'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(petControllerProvider(shelterId));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPetForm(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.pets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text(
                        'Aún no tienes mascotas publicadas',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Toca el botón + para agregar tu primera mascota',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.pets.length,
                  itemBuilder: (context, index) {
                    final pet = state.pets[index];
                    return PetCard(
                      pet: pet,
                      onEdit: () => _openPetForm(context, ref, pet: pet),
                      onDelete: () => _confirmDelete(context, ref, pet),
                    );
                  },
                ),
    );
  }
}

class _PetFormModal extends ConsumerWidget {
  final String shelterId;
  final Pet? pet;

  const _PetFormModal({
    required this.shelterId,
    this.pet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(petControllerProvider(shelterId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  pet == null ? 'Publicar mascota' : 'Editar mascota',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: state.isSaving
                      ? null
                      : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: PetForm(
              pet: pet,
              isSaving: state.isSaving,
              onSubmit: (petData, photoFile) async {
                final controller =
                    ref.read(petControllerProvider(shelterId).notifier);
                bool success;
                if (pet == null) {
                  success = await controller.createPet(
                    pet: petData,
                    photoFile: photoFile!,
                  );
                } else {
                  success = await controller.updatePet(
                    petId: pet!.id,
                    data: petData.toMap(shelterId),
                    newPhotoFile: photoFile,
                  );
                }
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(pet == null
                          ? 'Mascota publicada exitosamente'
                          : 'Mascota actualizada exitosamente'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}