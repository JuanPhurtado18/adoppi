import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../../data/chat_repository.dart';
import '../../domain/conversation.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  final bool isShelter;
  final String? shelterId;

  const ConversationsScreen({
    super.key,
    this.isShelter = false,
    this.shelterId,
  });

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _deleteConversation(Conversation conv) async {
    print('🗑️ [DELETE] Iniciando eliminación de conversación: ${conv.id}');
    try {
      print('🗑️ [DELETE] Eliminando mensajes de conversation_id: ${conv.id}');
      final msgResult = await Supabase.instance.client
          .from('messages')
          .delete()
          .eq('conversation_id', conv.id)
          .select();

      print('🗑️ [DELETE] Mensajes eliminados: $msgResult');

      print('🗑️ [DELETE] Eliminando conversación con id: ${conv.id}');
      final convResult = await Supabase.instance.client
          .from('conversations')
          .delete()
          .eq('id', conv.id)
          .select();

      print('🗑️ [DELETE] Resultado eliminación conversación: $convResult');

      if (convResult.isEmpty) {
        print(
          '⚠️ [DELETE] ADVERTENCIA: La query no eliminó ninguna fila. '
          '¿El id coincide? id usado: ${conv.id}',
        );
      }

      print('🗑️ [DELETE] Invalidando providers...');
      if (widget.isShelter && widget.shelterId != null) {
        print(
          '🗑️ [DELETE] Invalidando shelterConversationsProvider(${widget.shelterId})',
        );
        ref.invalidate(shelterConversationsProvider(widget.shelterId!));
      } else {
        print('🗑️ [DELETE] Invalidando adoptantConversationsProvider');
        ref.invalidate(adoptantConversationsProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversación eliminada'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stack) {
      print('❌ [DELETE] ERROR al eliminar: $e');
      print('❌ [DELETE] StackTrace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la conversación'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _confirmDelete() async {
    print('❓ [CONFIRM] Mostrando diálogo de confirmación...');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text(
          '¿Estás seguro que quieres eliminar esta conversación? Se eliminarán todos los mensajes permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    print('❓ [CONFIRM] Resultado del diálogo: $result');
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = widget.isShelter && widget.shelterId != null
        ? ref.watch(shelterConversationsProvider(widget.shelterId!))
        : ref.watch(adoptantConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  const Center(child: Text('Error al cargar conversaciones')),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    if (widget.isShelter && widget.shelterId != null) {
                      ref.invalidate(
                        shelterConversationsProvider(widget.shelterId!),
                      );
                    } else {
                      ref.invalidate(adoptantConversationsProvider);
                    }
                  },
                  child: _DismissibleList(
                    conversations: conversations,
                    isShelter: widget.isShelter,
                    shelterId: widget.shelterId,
                    timeLabel: _timeLabel,
                    onDelete: _deleteConversation,
                    onConfirmDelete: _confirmDelete,
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

class _DismissibleList extends StatefulWidget {
  final List<Conversation> conversations;
  final bool isShelter;
  final String? shelterId;
  final String Function(DateTime?) timeLabel;
  final Future<void> Function(Conversation) onDelete;
  final Future<bool> Function() onConfirmDelete;

  const _DismissibleList({
    required this.conversations,
    required this.isShelter,
    required this.shelterId,
    required this.timeLabel,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  @override
  State<_DismissibleList> createState() => _DismissibleListState();
}

class _DismissibleListState extends State<_DismissibleList> {
  late List<Conversation> _localConversations;

  @override
  void initState() {
    super.initState();
    _localConversations = List.from(widget.conversations);
  }

  @override
  void didUpdateWidget(_DismissibleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversations != widget.conversations) {
      _localConversations = List.from(widget.conversations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _localConversations.length,
      itemBuilder: (context, index) {
        final conv = _localConversations[index];
        return Dismissible(
          key: Key(conv.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.error,
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
          confirmDismiss: (direction) => widget.onConfirmDelete(),
          onDismissed: (direction) {
            print('👆 [DISMISS] onDismissed llamado para conv.id: ${conv.id}');
            print(
              '👆 [DISMISS] Lista local antes: ${_localConversations.map((c) => c.id).toList()}',
            );
            setState(() {
              _localConversations.removeAt(index);
            });
            print(
              '👆 [DISMISS] Lista local después: ${_localConversations.map((c) => c.id).toList()}',
            );
            widget.onDelete(conv);
          },
          child: _ConversationTile(
            conversation: conv,
            isShelter: widget.isShelter,
            shelterId: widget.shelterId,
            timeLabel: widget.timeLabel(conv.lastMessageAt),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final bool isShelter;
  final String? shelterId;
  final String timeLabel;

  const _ConversationTile({
    required this.conversation,
    required this.isShelter,
    this.shelterId,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onTap: () async {
            final fullConversation = await ref
                .read(chatRepositoryProvider)
                .getConversationById(conversation.id);

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversation: fullConversation,
                    isShelter: isShelter,
                  ),
                ),
              ).then((_) {
                if (isShelter && shelterId != null) {
                  ref.invalidate(shelterConversationsProvider(shelterId!));
                } else {
                  ref.invalidate(adoptantConversationsProvider);
                }
              });
            }
          },
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