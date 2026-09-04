import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_tab.dart';
import 'shelters_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _goToShelters() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onSeeAllShelters: _goToShelters),
      const SheltersTab(),
      const MessagesTab(),
      const AdoptantProfileTab(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            ref.invalidate(adoptantConversationsProvider);
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Refugios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
