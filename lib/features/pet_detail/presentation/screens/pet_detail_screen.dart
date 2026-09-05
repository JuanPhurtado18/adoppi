import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pet_detail_repository.dart';
import '../../data/adoption_request_repository.dart';
import '../../../shelter_panel/domain/pet.dart';
import '../widgets/info_chip.dart';
import '../widgets/shelter_mini_card.dart';
import 'shelter_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(petByIdProvider(widget.petId));
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      ref.invalidate(myRequestProvider((widget.petId, userId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petByIdProvider(widget.petId));

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

  Future<void> _showAdoptionDialog(BuildContext context, WidgetRef ref) async {
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar adopción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas solicitar la adopción de ${pet.name}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mensaje para el refugio (opcional)',
                hintText: 'Cuéntanos por qué quieres adoptar a esta mascota...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await ref
          .read(adoptionRequestRepositoryProvider)
          .createRequest(
            petId: pet.id,
            shelterId: pet.shelterId,
            adoptantId: userId,
            message: messageController.text.trim().isEmpty
                ? null
                : messageController.text.trim(),
          );

      ref.invalidate(myRequestProvider((pet.id, userId)));
      ref.invalidate(petByIdProvider(pet.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar la solicitud'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelterAsync = ref.watch(shelterByIdProvider(pet.shelterId));
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final myRequestAsync = ref.watch(myRequestProvider((pet.id, userId)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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
            actions: [
              GestureDetector(
                onTap: () {
                  ref.invalidate(petByIdProvider(pet.id));
                  ref.invalidate(myRequestProvider((pet.id, userId)));
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
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

                  // Condiciones
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

                  const SizedBox(height: 24),

                  // Botón I'm Interested
                  ElevatedButton(
                    onPressed: pet.adoptionStatus == 'disponible'
                        ? () async {
                            try {
                              final conversation = await ref
                                  .read(chatRepositoryProvider)
                                  .getOrCreateConversation(
                                    adoptantId: userId,
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

                  const SizedBox(height: 12),

                  // Botón Solicitar adopción
                  myRequestAsync.when(
                    loading: () => const SizedBox(
                      height: 52,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (request) {
                      if (pet.adoptionStatus == 'adoptado') {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.adopted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.adopted.withOpacity(0.3),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Esta mascota ya fue adoptada',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.adopted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                      if (request != null) {
                        final status = request['status'] as String;
                        Color statusColor;
                        String statusText;
                        IconData statusIcon;

                        switch (status) {
                          case 'pendiente':
                            statusColor = AppColors.warning;
                            statusText = 'Solicitud enviada — Pendiente';
                            statusIcon = Icons.hourglass_empty;
                            break;
                          case 'aprobada':
                            statusColor = AppColors.success;
                            statusText = '¡Solicitud aprobada!';
                            statusIcon = Icons.check_circle_outline;
                            break;
                          case 'rechazada':
                            statusColor = AppColors.error;
                            statusText = 'Solicitud rechazada';
                            statusIcon = Icons.cancel_outlined;
                            break;
                          default:
                            statusColor = AppColors.textHint;
                            statusText = status;
                            statusIcon = Icons.info_outline;
                        }

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (status == 'rechazada') ...[
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    _showAdoptionDialog(context, ref),
                                child: const Text('Volver a solicitar'),
                              ),
                            ],
                          ],
                        );
                      }

                      if (pet.adoptionStatus == 'disponible') {
                        return ElevatedButton(
                          onPressed: () => _showAdoptionDialog(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text('Solicitar adopción'),
                        );
                      }

                      return const SizedBox.shrink();
                    },
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
