import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class ChatRepository {
  final SupabaseClient _client;
  String? get currentUserId => _client.auth.currentUser?.id;
  ChatRepository(this._client);

  // Obtener o crear conversación
  Future<Conversation> getOrCreateConversation({
    required String adoptantId,
    required String shelterId,
    required String petId,
    required String petName,
  }) async {
    // Buscar conversación existente
    final existing = await _client
        .from('conversations')
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .eq('adoptant_id', adoptantId)
        .eq('shelter_id', shelterId)
        .eq('pet_id', petId)
        .maybeSingle();

    if (existing != null) {
      return Conversation.fromMap(existing);
    }

    // Crear nueva conversación
    final newConv = await _client
        .from('conversations')
        .insert({
          'adoptant_id': adoptantId,
          'shelter_id': shelterId,
          'pet_id': petId,
        })
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .single();

    final conversation = Conversation.fromMap(newConv);

    // Enviar mensaje inicial automático
    await sendMessage(
      conversationId: conversation.id,
      senderId: adoptantId,
      content:
          'Hola, estoy interesado en adoptar a $petName. ¿Me podrías dar más información?',
    );

    return conversation;
  }

  // Obtener conversaciones del adoptante
  Future<List<Conversation>> getAdoptantConversations(String adoptantId) async {
    final response = await _client
        .from('conversations')
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .eq('adoptant_id', adoptantId)
        .order('last_message_at', ascending: false);

    return (response as List).map((e) => Conversation.fromMap(e)).toList();
  }

  // Obtener conversaciones del refugio
  Future<List<Conversation>> getShelterConversations(String shelterId) async {
    final response = await _client
        .from('conversations')
        .select(
          '*, profiles(full_name, avatar_url), pets(name, main_photo_url)',
        )
        .eq('shelter_id', shelterId)
        .order('last_message_at', ascending: false);

    return (response as List).map((e) => Conversation.fromMap(e)).toList();
  }

  // Obtener mensajes de una conversación
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => Message.fromMap(e)).toList();
  }

  // Enviar mensaje
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();

    // Actualizar último mensaje en la conversación
    await _client
        .from('conversations')
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    return Message.fromMap(response);
  }

  // Stream de mensajes en tiempo real
  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((e) => Message.fromMap(e)).toList());
  }

  // Marcar mensajes como leídos
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});
