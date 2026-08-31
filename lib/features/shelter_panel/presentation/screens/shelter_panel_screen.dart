import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/shelter_controller.dart';
import 'pets_tab.dart';
import 'requests_tab.dart';
import 'profile_tab.dart';

class ShelterPanelScreen extends ConsumerStatefulWidget {
  const ShelterPanelScreen({super.key});

  @override
  ConsumerState<ShelterPanelScreen> createState() => _ShelterPanelScreenState();
}

class _ShelterPanelScreenState extends ConsumerState<ShelterPanelScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shelterState = ref.watch(shelterControllerProvider);
    final shelter = shelterState.shelter;

    if (shelterState.isLoading && shelter == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final shelterId = shelter?.id ?? '';

    final tabs = [
      PetsTab(shelterId: shelterId),
      RequestsTab(shelterId: shelterId),
      const ProfileTab(),
    ];

    final titles = ['Mis Mascotas', 'Solicitudes', 'Mi Refugio'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0 && shelter != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${shelterState.shelter?.name ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Mi Refugio',
          ),
        ],
      ),
    );
  }
}