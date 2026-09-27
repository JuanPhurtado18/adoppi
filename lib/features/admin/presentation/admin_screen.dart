import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../data/admin_repository.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header morado
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
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
                        'Panel de Administración',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón cerrar sesión
                GestureDetector(
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats rápidas
          Padding(
            padding: const EdgeInsets.all(16),
            child: usersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (users) {
                final adoptantes = users
                    .where((u) => u['role'] == 'adoptante')
                    .length;
                final refugios = users
                    .where((u) => u['role'] == 'refugio')
                    .length;
                final bloqueados = users
                    .where((u) => u['is_blocked'] == true)
                    .length;

                return Row(
                  children: [
                    _StatCard(
                      label: 'Adoptantes',
                      count: adoptantes,
                      icon: Icons.favorite_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Refugios',
                      count: refugios,
                      icon: Icons.home_outlined,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Bloqueados',
                      count: bloqueados,
                      icon: Icons.block_outlined,
                      color: AppColors.error,
                    ),
                  ],
                );
              },
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  Center(child: Text('Error al cargar usuarios: $e')),
              data: (users) => users.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay usuarios registrados',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(allUsersProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _UserCard(
                            user: user,
                            onManage: () =>
                                _showProfileModal(context, ref, user),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileModal(user: user, ref: ref),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onManage;

  const _UserCard({required this.user, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final isBlocked = user['is_blocked'] == true;
    final role = user['role'] as String? ?? 'adoptante';

    Color roleColor;
    String roleLabel;
    IconData roleIcon;

    switch (role) {
      case 'refugio':
        roleColor = AppColors.info;
        roleLabel = 'Refugio';
        roleIcon = Icons.home_outlined;
        break;
      default:
        roleColor = AppColors.primary;
        roleLabel = 'Adoptante';
        roleIcon = Icons.favorite_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBlocked
              ? AppColors.error.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.divider,
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: user['avatar_url'] == null
                    ? const Icon(Icons.person, color: AppColors.textHint)
                    : null,
              ),
              if (isBlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['full_name'] ?? ''} ${user['last_name'] ?? ''}'
                      .trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(roleIcon, size: 12, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: roleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bloqueado',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botón gestionar
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Gestionar\nperfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final WidgetRef ref;

  const _ProfileModal({required this.user, required this.ref});

  @override
  ConsumerState<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends ConsumerState<_ProfileModal> {
  late bool _isBlocked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.user['is_blocked'] == true;
  }

  Future<void> _toggleBlock() async {
    setState(() => _isLoading = true);
    try {
      if (_isBlocked) {
        await ref.read(adminRepositoryProvider).unblockUser(widget.user['id']);
      } else {
        await ref.read(adminRepositoryProvider).blockUser(widget.user['id']);
      }
      setState(() => _isBlocked = !_isBlocked);
      ref.invalidate(allUsersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBlocked
                  ? 'Perfil bloqueado exitosamente'
                  : 'Perfil desbloqueado exitosamente',
            ),
            backgroundColor: _isBlocked ? AppColors.error : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] as String? ?? 'adoptante';
    final detailsAsync = ref.watch(
      userDetailsProvider(widget.user['id'] as String),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header de la modal
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Detalles del perfil',
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

          // Contenido
          Expanded(
            child: detailsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  const Center(child: Text('Error al cargar detalles')),
              data: (details) {
                if (details == null) return const SizedBox.shrink();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar y nombre
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.divider,
                              backgroundImage: details['avatar_url'] != null
                                  ? NetworkImage(details['avatar_url'])
                                  : null,
                              child: details['avatar_url'] == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppColors.textHint,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${details['full_name'] ?? ''} ${details['last_name'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: role == 'refugio'
                                    ? AppColors.info.withOpacity(0.1)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role == 'refugio' ? 'Refugio' : 'Adoptante',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: role == 'refugio'
                                      ? AppColors.info
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información personal
                      const Text(
                        'Información',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.email_outlined,
                              label: 'Correo',
                              value:
                                  details['email'] ??
                                  Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.email ??
                                  'No disponible',
                            ),
                            if (details['phone'] != null) ...[
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                label: 'Teléfono',
                                value: details['phone'],
                              ),
                            ],
                            if (details['city'] != null) ...[
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.location_city_outlined,
                                label: 'Ciudad',
                                value: details['city'],
                              ),
                            ],
                            if (details['age'] != null) ...[
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.cake_outlined,
                                label: 'Edad',
                                value: '${details['age']} años',
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Info del refugio si aplica
                      if (role == 'refugio' && details['shelter'] != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Información del Refugio',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.home_outlined,
                                label: 'Nombre',
                                value:
                                    details['shelter']['name'] ??
                                    'No disponible',
                              ),
                              if (details['shelter']['address'] != null) ...[
                                const Divider(height: 1),
                                _DetailRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Dirección',
                                  value: details['shelter']['address'],
                                ),
                              ],
                              if (details['shelter']['phone'] != null) ...[
                                const Divider(height: 1),
                                _DetailRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Teléfono',
                                  value: details['shelter']['phone'],
                                ),
                              ],
                              if (details['shelter']['schedule'] != null) ...[
                                const Divider(height: 1),
                                _DetailRow(
                                  icon: Icons.schedule_outlined,
                                  label: 'Horario',
                                  value: details['shelter']['schedule'],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Botón bloquear / desbloquear
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleBlock,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isBlocked
                                    ? Icons.lock_open_outlined
                                    : Icons.block_outlined,
                              ),
                        label: Text(
                          _isBlocked ? 'Desbloquear perfil' : 'Bloquear perfil',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isBlocked
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
