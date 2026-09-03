import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pet_detail_repository.dart';
import '../../../shelter_panel/domain/shelter.dart';
import '../../../shelter_panel/domain/pet.dart';
import '../../../home/presentation/widgets/pet_card_home.dart';
import 'pet_detail_screen.dart';

class ShelterDetailScreen extends ConsumerWidget {
  final String shelterId;

  const ShelterDetailScreen({super.key, required this.shelterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelterAsync = ref.watch(shelterByIdProvider(shelterId));
    final petsAsync = ref.watch(shelterPetsProvider(shelterId));

    return shelterAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Error al cargar el refugio')),
      ),
      data: (shelter) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // AppBar con foto
            SliverAppBar(
              expandedHeight: 220,
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
                background: shelter.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: shelter.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary,
                          child: const Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primary,
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
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
                    // Nombre y verificado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shelter.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (shelter.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.available.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.verified,
                                  color: AppColors.available,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verificado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.available,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Descripción
                    if (shelter.description != null) ...[
                      Text(
                        shelter.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Próximamente'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                            ),
                            label: const Text('Contactar'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Próximamente'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.directions_outlined,
                              size: 18,
                            ),
                            label: const Text('Cómo llegar'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Información de contacto
                    const Text(
                      'Información',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          if (shelter.address != null)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              text: shelter.address!,
                            ),
                          if (shelter.address != null &&
                              (shelter.schedule != null ||
                                  shelter.phone != null ||
                                  shelter.email != null))
                            const Divider(height: 1),
                          if (shelter.schedule != null)
                            _InfoRow(
                              icon: Icons.schedule_outlined,
                              text: shelter.schedule!,
                            ),
                          if (shelter.schedule != null &&
                              (shelter.phone != null || shelter.email != null))
                            const Divider(height: 1),
                          if (shelter.phone != null)
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              text: shelter.phone!,
                            ),
                          if (shelter.phone != null && shelter.email != null)
                            const Divider(height: 1),
                          if (shelter.email != null)
                            _InfoRow(
                              icon: Icons.email_outlined,
                              text: shelter.email!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mascotas disponibles
                    const Text(
                      'Mascotas Disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Grid de mascotas
            petsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => const SliverToBoxAdapter(
                child: Center(child: Text('Error al cargar mascotas')),
              ),
              data: (pets) => pets.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No hay mascotas disponibles',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final pet = pets[index];
                          return PetCardHome(
                            pet: pet,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PetDetailScreen(petId: pet.id),
                                ),
                              );
                            },
                          );
                        }, childCount: pets.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
