import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'notifications_provider.dart';

class NotificationsModal extends ConsumerStatefulWidget {
  const NotificationsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsModal(),
    );
  }

  @override
  ConsumerState<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends ConsumerState<NotificationsModal> {
  String _selectedFilter = 'Todas';

  final List<String> _filters = [
    'Todas',
    'No leídas',
    'Leídas',
    'Adopciones',
    'Mensajes',
  ];

  final Set<String> _locallyRead = {};
  final Set<String> _deletedIds = {};

  String _timeLabel(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'solicitud_aprobada':
        return Icons.favorite_outline;
      case 'solicitud_recibida':
        return Icons.pets;
      case 'nuevo_mensaje':
        return Icons.chat_bubble_outline;
      case 'nueva_mascota':
        return Icons.cruelty_free_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'solicitud_aprobada':
        return AppColors.success;
      case 'solicitud_recibida':
      case 'nuevo_mensaje':
      case 'nueva_mascota':
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }

  bool _isRead(Map<String, dynamic> notif) {
    return (notif['is_read'] as bool? ?? false) ||
        _locallyRead.contains(notif['id']);
  }

  Future<void> _markAsRead(Map<String, dynamic> notif) async {
    final id = notif['id'] as String?;
    if (id == null || _isRead(notif)) return;

    setState(() => _locallyRead.add(id));

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    ref.invalidate(unreadCountProvider);
  }

  Future<void> _markAllAsReadManual(
    List<Map<String, dynamic>> notifications,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final unreadIds = notifications
        .where((n) => !_isRead(n))
        .map((n) => n['id'] as String)
        .toList();

    if (unreadIds.isEmpty) return;

    setState(() => _locallyRead.addAll(unreadIds));

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _softDelete(String id) async {
    setState(() => _deletedIds.add(id));

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'deleted_by_user': true})
          .eq('id', id)
          .select();
    } catch (e) {
      print('❌ [DELETE] Error: $e');
    }

    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> notifications,
  ) {
    final visible = notifications
        .where((n) => !_deletedIds.contains(n['id']))
        .toList();

    switch (_selectedFilter) {
      case 'No leídas':
        return visible.where((n) => !_isRead(n)).toList();
      case 'Leídas':
        return visible.where((n) => _isRead(n)).toList();
      case 'Adopciones':
        return visible
            .where(
              (n) =>
                  n['type'] == 'solicitud_aprobada' ||
                  n['type'] == 'solicitud_recibida',
            )
            .toList();
      case 'Mensajes':
        return visible.where((n) => n['type'] == 'nuevo_mensaje').toList();
      default:
        return visible;
    }
  }

  int _unreadCount(List<Map<String, dynamic>> notifications) {
    return notifications
        .where((n) => !_deletedIds.contains(n['id']) && !_isRead(n))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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

          notificationsAsync.when(
            loading: () => _buildHeader(context, 0, []),
            error: (_, __) => _buildHeader(context, 0, []),
            data: (notifications) => _buildHeader(
              context,
              _unreadCount(notifications),
              notifications,
            ),
          ),

          _buildFilterTabs(),

          const Divider(height: 1),

          Expanded(
            child: notificationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  const Center(child: Text('Error al cargar notificaciones')),
              data: (notifications) {
                final filtered = _applyFilter(notifications);
                final isUnreadTab = _selectedFilter == 'No leídas';
                final isReadTab = _selectedFilter == 'Leídas';

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'Todas'
                              ? 'No tienes notificaciones'
                              : 'No hay notificaciones en esta categoría',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 76),
                  itemBuilder: (context, index) {
                    final notif = filtered[index];
                    final type = notif['type'] as String? ?? '';
                    final isRead = _isRead(notif);
                    final id = notif['id'] as String;

                    final tile = _NotificationTile(
                      notif: notif,
                      type: type,
                      isRead: isRead,
                      icon: _typeIcon(type),
                      iconColor: _typeColor(type),
                      timeLabel: _timeLabel(notif['created_at']),
                    );

                    if (isUnreadTab) {
                      return Dismissible(
                        key: Key(id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.success,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.done_all,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Leído',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => _markAsRead(notif),
                        child: tile,
                      );
                    }

                    if (isReadTab) {
                      return Dismissible(
                        key: Key(id),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: AppColors.error,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => _softDelete(id),
                        child: tile,
                      );
                    }

                    return tile;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int unreadCount,
    List<Map<String, dynamic>> notifications,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '$unreadCount no leída${unreadCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (unreadCount > 0)
                GestureDetector(
                  onTap: () => _markAllAsReadManual(notifications),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      '✓ Marcar todo',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final String type;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final String timeLabel;

  const _NotificationTile({
    required this.notif,
    required this.type,
    required this.isRead,
    required this.icon,
    required this.iconColor,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.04),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif['body'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
