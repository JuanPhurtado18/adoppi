import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/chat_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';

final adoptantConversationsProvider = FutureProvider<List<Conversation>>((
  ref,
) async {
  final repo = ref.watch(chatRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return repo.getAdoptantConversations(userId);
});

final shelterConversationsProvider =
    FutureProvider.family<List<Conversation>, String>((ref, shelterId) async {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.getShelterConversations(shelterId);
    });

final conversationByIdProvider = FutureProvider.family<Conversation, String>((
  ref,
  conversationId,
) async {
  return ref.watch(chatRepositoryProvider).getConversationById(conversationId);
});

final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.messagesStream(conversationId);
});
