import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../data/home_repository.dart';

final adoptantProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  return response;
});

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
final petPreferencesProvider = StateProvider<List<String>>((ref) => []);

class AdoptantProfileTab extends ConsumerStatefulWidget {
  const AdoptantProfileTab({super.key});

  @override
  ConsumerState<AdoptantProfileTab> createState() => _AdoptantProfileTabState();
}

class _AdoptantProfileTabState extends ConsumerState<AdoptantProfileTab> {
  bool _preferencesLoaded = false;

  void _loadPreferences(Map<String, dynamic>? profile) {
    if (_preferencesLoaded || profile == null) return;
    final prefs = profile['pet_preferences'];
    if (prefs != null) {
      final list = (prefs as List).map((e) => e.toString()).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(petPreferencesProvider.notifier).state = list;
      });
    }
    _preferencesLoaded = true;
  }

  Future<void> _openPetPreferences() async {
    final current = ref.read(petPreferencesProvider);
    List<String> temp = List.from(current);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void toggle(String pref) {
            setModalState(() {
              if (temp.contains(pref)) {
                temp.remove(pref);
              } else {
                temp.add(pref);
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Pet Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de mascota',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PreferenceChip(
                              label: 'Dogs',
                              isSelected: temp.contains('dogs'),
                              onTap: () => toggle('dogs'),
                            ),
                            _PreferenceChip(
                              label: 'Cats',
                              isSelected: temp.contains('cats'),
                              onTap: () => toggle('cats'),
                            ),
                            _PreferenceChip(
                              label: 'Small Pets',
                              isSelected: temp.contains('small_pets'),
                              onTap: () => toggle('small_pets'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Edad',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PreferenceChip(
                              label: 'Young',
                              isSelected: temp.contains('young'),
                              onTap: () => toggle('young'),
                            ),
                            _PreferenceChip(
                              label: 'Adult',
                              isSelected: temp.contains('adult'),
                              onTap: () => toggle('adult'),
                            ),
                            _PreferenceChip(
                              label: 'Senior',
                              isSelected: temp.contains('senior'),
                              onTap: () => toggle('senior'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId == null) return;

                      await ref
                          .read(homeRepositoryProvider)
                          .updatePetPreferences(
                            userId: userId,
                            preferences: temp,
                          );

                      ref.read(petPreferencesProvider.notifier).state =
                          List.from(temp);
                      ref.invalidate(adoptantProfileProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Preferencias guardadas exitosamente',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Guardar preferencias'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adoptantProfileProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final selectedPreferences = ref.watch(petPreferencesProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => const Center(child: Text('Error al cargar el perfil')),
        data: (profile) {
          _loadPreferences(profile);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header morado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      // Foto de perfil
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(
                              child: profile?['avatar_url'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: profile!['avatar_url'],
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.person,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${profile?['full_name'] ?? ''} ${profile?['last_name'] ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sección Pet Preferences
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pet Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      selectedPreferences.isEmpty
                          ? Text(
                              'No tienes preferencias configuradas',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedPreferences.map((pref) {
                                final labels = {
                                  'dogs': 'Dogs',
                                  'cats': 'Cats',
                                  'small_pets': 'Small Pets',
                                  'young': 'Young',
                                  'adult': 'Adult',
                                  'senior': 'Senior',
                                };
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    labels[pref] ?? pref,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: _SettingsTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notificaciones',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notificationsEnabled
                                    ? 'Activadas'
                                    : 'Desactivadas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () {
                            ref
                                    .read(notificationsEnabledProvider.notifier)
                                    .state =
                                !notificationsEnabled;
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Material(
                        color: Colors.transparent,
                        child: _SettingsTile(
                          icon: Icons.location_on_outlined,
                          label: 'Ubicación',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile?['city'] ?? 'No definida',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () {},
                        ),
                      ),
                      const Divider(height: 1),
                      Material(
                        color: Colors.transparent,
                        child: _SettingsTile(
                          icon: Icons.favorite_outline,
                          label: 'Pet Preferences',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          onTap: _openPetPreferences,
                        ),
                      ),
                      const Divider(height: 1),
                      Material(
                        color: Colors.transparent,
                        child: _SettingsTile(
                          icon: Icons.shield_outlined,
                          label: 'Privacy & Safety',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          onTap: () {},
                        ),
                      ),
                      const Divider(height: 1),
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: _SettingsTile(
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Log Out
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Version
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Made with ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          Icon(
                            Icons.favorite,
                            color: AppColors.error,
                            size: 12,
                          ),
                          Text(
                            ' for pets',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PreferenceChip({
    required this.label,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
