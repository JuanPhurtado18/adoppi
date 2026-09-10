import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'notifications_provider.dart';
import 'notifications_modal.dart';

class NotificationBell extends ConsumerWidget {
  final Color iconColor;

  const NotificationBell({super.key, this.iconColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider);

    return GestureDetector(
      onTap: () async {
        await NotificationsModal.show(context);
        // Refrescar después de cerrar el modal
        ref.invalidate(unreadCountProvider);
        ref.invalidate(notificationsProvider);
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.notifications_outlined,
              color: iconColor,
              size: 24,
            ),
          ),
          unreadAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (count) => count == 0
                ? const SizedBox.shrink()
                : Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
