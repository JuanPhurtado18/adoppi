import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/pet_card_home.dart';
import '../widgets/shelter_card_home.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => controller.loadAll(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adoppi',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Encuentra tu compañero perfecto',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.favorite, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: controller.search,
                      decoration: InputDecoration(
                        hintText: 'Buscar refugios o mascotas...',
                        hintStyle: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textHint,
                        ),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  controller.clearSearch();
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textHint,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Filtros por especie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _SpeciesChip(
                    label: 'Todos',
                    icon: Icons.pets,
                    isSelected: state.selectedSpecies == 'todos',
                    onTap: () => controller.filterBySpecies('todos'),
                  ),
                  const SizedBox(width: 8),
                  _SpeciesChip(
                    label: 'Perros',
                    icon: Icons.cruelty_free,
                    isSelected: state.selectedSpecies == 'perro',
                    onTap: () => controller.filterBySpecies('perro'),
                  ),
                  const SizedBox(width: 8),
                  _SpeciesChip(
                    label: 'Gatos',
                    icon: Icons.cruelty_free,
                    isSelected: state.selectedSpecies == 'gato',
                    onTap: () => controller.filterBySpecies('gato'),
                  ),
                  const SizedBox(width: 8),
                  _SpeciesChip(
                    label: 'Otros',
                    icon: Icons.cruelty_free,
                    isSelected: state.selectedSpecies == 'otro',
                    onTap: () => controller.filterBySpecies('otro'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sección refugios cercanos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Refugios Cercanos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Ver todos')),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lista horizontal de refugios
            SizedBox(
              height: 170,
              child: state.isLoadingShelters
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : state.shelters.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay refugios registrados',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.shelters.length,
                      itemBuilder: (context, index) {
                        final shelter = state.shelters[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ShelterCardHome(
                            shelter: shelter,
                            onTap: () {},
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Sección mascotas disponibles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mascotas Disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${state.pets.length} encontradas',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grid de mascotas
            state.isLoadingPets
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : state.pets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.pets,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.searchQuery.isNotEmpty
                                ? 'No se encontraron mascotas para "${state.searchQuery}"'
                                : 'No hay mascotas disponibles',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: state.pets.length,
                    itemBuilder: (context, index) {
                      final pet = state.pets[index];
                      return PetCardHome(pet: pet, onTap: () {});
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeciesChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
