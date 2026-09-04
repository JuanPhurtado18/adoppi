import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pet_detail_repository.dart';
import '../../../shelter_panel/domain/pet.dart';
import '../widgets/info_chip.dart';
import '../widgets/shelter_mini_card.dart';
import 'shelter_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class PetDetailScreen extends ConsumerWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petByIdProvider(petId));

    return petAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Error al cargar la mascota')),
      ),
      data: (pet) => _PetDetailContent(pet: pet),
    );
  }
}

class _PetDetailContent extends ConsumerWidget {
  final Pet pet;

  const _PetDetailContent({required this.pet});

  String _genderLabel(String? gender) {
    switch (gender) {
      case 'macho':
        return 'Macho';
      case 'hembra':
        return 'Hembra';
      default:
        return 'N/A';
    }
  }

  String _sizeLabel(String? size) {
    switch (size) {
      case 'pequeño':
        return 'Pequeño';
      case 'mediano':
        return 'Mediano';
      case 'grande':
        return 'Grande';
      default:
        return 'N/A';
    }
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    final shelterAsync = ref.watch(shelterByIdProvider(pet.shelterId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar con foto
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: pet.mainPhotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: pet.mainPhotoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.divider,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.divider,
                        child: const Icon(
                          Icons.pets,
                          color: AppColors.textHint,
                          size: 64,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.divider,
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.textHint,
                        size: 64,
                      ),
                    ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor().withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            color: _statusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Raza y especie
                  Text(
                    pet.breed != null
                        ? '${pet.breed} · ${pet.species}'
                        : pet.species,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info chips
                  Row(
                    children: [
                      Expanded(
                        child: InfoChip(
                          icon: Icons.cake_outlined,
                          label: 'Edad',
                          value: petAgeLabel(pet.ageMonths),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InfoChip(
                          icon: pet.gender == 'macho'
                              ? Icons.male
                              : Icons.female,
                          label: 'Género',
                          value: _genderLabel(pet.gender),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InfoChip(
                          icon: Icons.straighten,
                          label: 'Tamaño',
                          value: _sizeLabel(pet.size),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Personalidad / condiciones
                  const Text(
                    'Condiciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pet.vaccinated) _ConditionChip(label: 'Vacunado'),
                      if (pet.sterilized) _ConditionChip(label: 'Esterilizado'),
                      if (pet.dewormed) _ConditionChip(label: 'Desparasitado'),
                      if (pet.childFriendly) _ConditionChip(label: 'Con niños'),
                      if (!pet.vaccinated &&
                          !pet.sterilized &&
                          !pet.dewormed &&
                          !pet.childFriendly)
                        const Text(
                          'Sin condiciones registradas',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),

                  // Historia
                  if (pet.story != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Historia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.story!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Descripción
                  if (pet.description != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Estado de salud
                  if (pet.healthStatus != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Estado de salud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.healthStatus!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Refugio responsable
                  const SizedBox(height: 24),
                  const Text(
                    'Shelter Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  shelterAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => const Text('Error al cargar refugio'),
                    data: (shelter) => ShelterMiniCard(
                      shelter: shelter,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ShelterDetailScreen(shelterId: shelter.id),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: pet.adoptionStatus == 'disponible'
                        ? () async {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user == null) return;

                            final shelter = ref
                                .read(shelterByIdProvider(pet.shelterId))
                                .value;
                            if (shelter == null) return;

                            try {
                              final conversation = await ref
                                  .read(chatRepositoryProvider)
                                  .getOrCreateConversation(
                                    adoptantId: user.id,
                                    shelterId: pet.shelterId,
                                    petId: pet.id,
                                    petName: pet.name,
                                  );

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversation: conversation,
                                      isShelter: false,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al abrir el chat'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text("I'm Interested"),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;

  const _ConditionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
