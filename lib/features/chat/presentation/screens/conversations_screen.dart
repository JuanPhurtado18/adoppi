import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../../domain/conversation.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  final bool isShelter;
  final String? shelterId;

  const ConversationsScreen({
    super.key,
    this.isShelter = false,
    this.shelterId,
  });

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = isShelter && shelterId != null
        ? ref.watch(shelterConversationsProvider(shelterId!))
        : ref.watch(adoptantConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            color: Colors.white,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mensajes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  const Center(child: Text('Error al cargar conversaciones')),
              data: (conversations) => conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes conversaciones aún',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        if (isShelter && shelterId != null) {
                          ref.invalidate(
                            shelterConversationsProvider(shelterId!),
                          );
                        } else {
                          ref.invalidate(adoptantConversationsProvider);
                        }
                      },
                      child: ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          return _ConversationTile(
                            conversation: conv,
                            isShelter: isShelter,
                            timeLabel: _timeLabel(conv.lastMessageAt),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversation: conv,
                                    isShelter: isShelter,
                                  ),
                                ),
                              ).then((_) {
                                if (isShelter && shelterId != null) {
                                  ref.invalidate(
                                    shelterConversationsProvider(shelterId!),
                                  );
                                } else {
                                  ref.invalidate(adoptantConversationsProvider);
                                }
                              });
                            },
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
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isShelter;
  final String timeLabel;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.isShelter,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shelterAvatar = conversation.shelterInfo?['avatar_url'] as String?;
    final adoptantAvatar = conversation.adoptantInfo?['avatar_url'] as String?;
    final avatarUrl = isShelter ? adoptantAvatar : shelterAvatar;

    final shelterName =
        conversation.shelterInfo?['name'] as String? ?? 'Refugio';
    final adoptantName =
        conversation.adoptantInfo?['full_name'] as String? ?? 'Adoptante';
    final name = isShelter ? adoptantName : shelterName;

    final petName = conversation.petInfo?['name'] as String?;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.divider,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.textHint)
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (petName != null)
                Text(
                  'Sobre: $petName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (conversation.lastMessage != null)
                Text(
                  conversation.lastMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 76),
      ],
    );
  }
}
