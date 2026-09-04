import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

class ChatRepository {
  final SupabaseClient _client;
  String? get currentUserId => _client.auth.currentUser?.id;

  ChatRepository(this._client);

  Future<Conversation> getOrCreateConversation({
    required String adoptantId,
    required String shelterId,
    String? petId,
    required String petName,
  }) async {
    // Buscar cualquier conversación existente con este refugio
    final existingList = await _client
        .from('conversations')
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .eq('adoptant_id', adoptantId)
        .eq('shelter_id', shelterId)
        .order('created_at', ascending: false)
        .limit(1);

    if ((existingList as List).isNotEmpty) {
      final existing = Conversation.fromMap(existingList.first);

      // Si viene desde una mascota específica, siempre enviar el mensaje
      // de interés aunque la conversación ya exista
      if (petId != null) {
        if (existing.petId == null) {
          await _client
              .from('conversations')
              .update({'pet_id': petId})
              .eq('id', existing.id);
        }

        // Verificar si ya se envió un mensaje de interés por esta mascota
        final existingMessage = await _client
            .from('messages')
            .select()
            .eq('conversation_id', existing.id)
            .eq('sender_id', adoptantId)
            .ilike('content', '%$petName%')
            .limit(1);

        if ((existingMessage as List).isEmpty) {
          await sendMessage(
            conversationId: existing.id,
            senderId: adoptantId,
            content:
                'Hola, estoy interesado en adoptar a $petName. ¿Me podrías dar más información?',
          );
        }

        final updated = await _client
            .from('conversations')
            .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
            .eq('id', existing.id)
            .single();

        return Conversation.fromMap(updated);
      }

      // Si viene desde contactar refugio sin mascota, solo abrir la conversación
      return existing;
    }

    // No existe ninguna conversación, crear una nueva
    final insertData = {
      'adoptant_id': adoptantId,
      'shelter_id': shelterId,
      if (petId != null) 'pet_id': petId,
    };

    final newConv = await _client
        .from('conversations')
        .insert(insertData)
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .single();

    final conversation = Conversation.fromMap(newConv);

    final message = petId != null
        ? 'Hola, estoy interesado en adoptar a $petName. ¿Me podrías dar más información?'
        : 'Hola, me gustaría obtener información sobre sus mascotas disponibles.';

    await sendMessage(
      conversationId: conversation.id,
      senderId: adoptantId,
      content: message,
    );

    return conversation;
  }

  Future<List<Conversation>> getAdoptantConversations(String adoptantId) async {
    final response = await _client
        .from('conversations')
        .select('*, shelters(name, avatar_url), pets(name, main_photo_url)')
        .eq('adoptant_id', adoptantId)
        .order('last_message_at', ascending: false);

    return (response as List).map((e) => Conversation.fromMap(e)).toList();
  }

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

  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => Message.fromMap(e)).toList();
  }

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

    await _client
        .from('conversations')
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    return Message.fromMap(response);
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((list) => list.map((e) => Message.fromMap(e)).toList());
  }

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

  Future<Conversation> getConversationById(String conversationId) async {
    final response = await _client
        .from('conversations')
        .select('''
          *,
          shelters(name, avatar_url),
          profiles(full_name, avatar_url),
          pets(name, main_photo_url)
        ''')
        .eq('id', conversationId)
        .single();

    return Conversation.fromMap(response);
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});
